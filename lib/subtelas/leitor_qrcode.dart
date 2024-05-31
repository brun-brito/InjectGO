import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRCodePage extends StatefulWidget {
  final String username;
  const QRCodePage({super.key, required this.username});

  @override
  // ignore: library_private_types_in_public_api
  _QRCodePageState createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  String ticket = '';
  late bool status;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  List<String> idsValidos = ['01-CE-FOR']; //TODO: Adicionar as maquinas aqui
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
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

    final CollectionReference scans = firestore.collection('leituras-maquinas');
    await scans.add({
      'nome': nome,
      'cpf': cpf,
      'id-maquina': code,
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
      _registerScanEvent(ticket, widget.username);
      _handleAuthentication(ticket);
    }
  }

  Future<void> _handleAuthentication(String code) async {
    if (code == "01-CE-FOR") {
      _showDialog('Sucesso!', 'ID da máquina válido! Máquina será liberada para compras.', true);
      status = true;
    } else {
      _showDialog('Erro!', 'ID da máquina inválido! Confira o código e tente novamente.', false);
      status = false;
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
    body: SingleChildScrollView(
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
            if (!idsValidos.contains(ticket)) // se o valor escaneado nao estiver na lista de ids válidos (ou seja, for inválido), ele exibe o botao dnv
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
  );
}

}