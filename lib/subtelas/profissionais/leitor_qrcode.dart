// ignore_for_file: empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRCodePage extends StatefulWidget {
  final String username;
  const QRCodePage({super.key, required this.username});

  @override
  // ignore: library_private_types_in_public_api
  _QRCodePageState createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  String ticket = '';
  String status = '';
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  List<String> idsValidos = [];
  String? chip;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool enviouSms = false; 
  bool isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void setLoading(bool valor){
    setState(() {
      isLoading = valor;
    });
    if (isLoading) {
      _timer = Timer(const Duration(seconds: 30), () {
        if (isLoading) {
          setLoading(false);
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.asset('assets/videos/qr_tutorial.mp4');
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: 16 / 9,
      autoPlay: false,
      looping: true,
      autoInitialize: true,
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _registerScanEvent(String code, String username) async {
    String nome = '';
    String cpf = '';
    var emailQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: widget.username)
      .limit(1)
      .get();

    if (emailQuery.docs.isNotEmpty) {
      final userDoc = emailQuery.docs.first;
      nome = userDoc['nome'] + ' ' + userDoc['sobrenome'];
      cpf = userDoc['cpf'];
    }

    String randomId = firestore.collection('leituras-maquinas').doc().id;
    final String documentId = '$nome - ${DateTime.now()}';
    final CollectionReference scans = firestore.collection('leituras-maquinas');
    await scans.doc(documentId).set({
      'id-transacao': randomId,
      'nome': nome,
      'cpf': cpf,
      'id-lido': code,
      'data-hora': FieldValue.serverTimestamp(),
      'status': status,
    });
  }
  
  Future<void> readQRCode() async {
    String code = await FlutterBarcodeScanner.scanBarcode(
      "#FFFFFF",
      "Cancelar",
      true,
      ScanMode.QR
    );
    setState(() => ticket = code != '-1' ? code : 'Inválido!');
    if (ticket != 'Inválido!') {
      await _handleAuthentication(ticket);
      _registerScanEvent(ticket, widget.username);
    }
  }

  Future<void> sendSMS2(String numero, String mensagem) async {
    String url = 'https://sms.comtele.com.br/api/v2/send';
    String authKey = 'd338d07f-94de-4efb-81a8-626efa245e0b';

    final Map<String, String> headers = {
      'content-type': 'application/json',
      'auth-key': authKey,
    };

    final Map<String, String> body = {
      'Receivers': numero,
      'Content': mensagem,
    };

    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
        enviouSms = true;
      } else {
        enviouSms = false;
    }
  }

    Future<void> sendSMS(String number, String message) async {
    String baseUrl = "https://api.nvoip.com.br/v2/sms";
    String napiKey= "T21HY2gyU1pnM2ZqM1ZoTlo5YjlZZjUzbFNtNmFEN2o=";
    final url = Uri.parse('$baseUrl?napikey=$napiKey');

    final Map<String, dynamic> bodyParameters = {
      "numberPhone": number,
      "message": message,
      "flashSms": false
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyParameters),
      );

      if (response.statusCode == 200) {
        enviouSms = true;
      } else {
        enviouSms = false;
      }
    } catch (e) {
        enviouSms = false;
    }
  }

  Future<void> lerIdsEChip(String code) async {
    try {
      QuerySnapshot snapshot = await firestore.collection('maquinas').get();
      List<String> ids = snapshot.docs.map((doc) => doc['id-maquina'].toString()).toList();
      setState(() {
        idsValidos = ids;
      });

      QuerySnapshot querySnapshot = await firestore
          .collection('maquinas')
          .where('id-maquina', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        chip = querySnapshot.docs.first['chip'].toString();
      }
    } catch (e) {}
  }


  Future<void> _handleAuthentication(String code) async {
    await lerIdsEChip(code);
    if (idsValidos.contains(code)) {
      setLoading(true);  
      try {
        await sendSMS(chip!, code); 
        if (!enviouSms) {
          await sendSMS2(chip!, code);            
        }
      } catch (e) {}
      setLoading(false);
      if (enviouSms){  //se ele conseguir ler o QRCode e mandar o SMS, ele libera a máquina
        _showDialog('Sucesso!', 'ID da máquina válido! Por favor, aguarde a máquina ser liberada para compras.', true);
        status = "Leu corretamente o QR code e mandou SMS";
      }
      else{
        _showDialog('Erro!', 'Não foi possível liberar a máquina para compras. Tente novamente mais tarde.', false);
        status = "Leu corretamente o QR code, mas deu erro no envio do SMS";
      }
    } else {
      setLoading(false);
      _showDialog('Erro!', 'ID da máquina inválido! Confira o código e tente novamente.', false);
      status = "Leu incorretamente o QR code";
    }
  }

  void _showDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              if (isSuccess) {                
                Navigator.of(context).pop();
              }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Aspect ratio do vídeo
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Clique no botão abaixo e escaneie o QR code da máquina, assim como no vídeo mostrado.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!idsValidos.contains(ticket) || enviouSms == false) // se o valor escaneado nao estiver na lista de ids válidos (ou seja, for inválido), ele exibe o botao dnv
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 90),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onPressed: readQRCode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Validar QR Code'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 236, 63, 121))),
                  SizedBox(height: 24),
                  Text(
                    'Processando...\nCaso demore mais do que 30 segundos, entre em contato conosco!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}