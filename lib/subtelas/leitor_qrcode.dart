import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRViewExample extends StatefulWidget {
  final String username;
  const QRViewExample({super.key, required this.username});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? _qrController;
  Color borderColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      _qrController?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)),
            (Route<dynamic> route) => false,
          );
        },
      ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: borderColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(35, 20, 35, 10),
            child: Expanded(
              flex: 1,
              child: Center(
                child: (result != null)
                ? Text('QR Code incorreto detectado: ${result!.code}')
                : const Text(
                    'Escaneie o QR Code da máquina no quadrado acima, ou clique no botão abaixo para digitar o ID manualmente.',
                    style: TextStyle(fontSize: 18), textAlign: TextAlign.center,
                  ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 30), 
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), 
                ),
              ),
              onPressed: () {
                _openDialog();
              },
              child: const Text('Digitar ID'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (scanData.code != null) {
          _handleAuthentication(scanData.code!);
        }
      });
    });
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String typedId = '';
        return AlertDialog(
          title: const Text('Digite o ID da máquina:'),
          content: TextField(
            onChanged: (value) {
              typedId = value;
            },
            decoration: const InputDecoration(hintText: 'ID da máquina'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enviar', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
                _handleAuthentication(typedId);
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAuthentication(String code) async {
    if (code == "01-CE-FOR") {
      setState(() {
        borderColor = Colors.green;
      });
      await Future.delayed(const Duration(seconds: 1));
      _showDialog('ID da máquina válido! Máquina será liberada para compras.', true);
    } else {
      setState(() {
        borderColor = Colors.red;
      });
      await Future.delayed(const Duration(seconds: 1));
      _showDialog('ID da máquina inválido! Confira o código e tente novamente.', false);
    }
  }

  void _showDialog(String message, bool isValid) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Atenção!'),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop(); 
              if (isValid) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)),
                  (Route<dynamic> route) => false,
                );
              }
              else{Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => QRViewExample(username: widget.username)),
                  (Route<dynamic> route) => false,
                );
                
              }
            },
          ),
        ],
      );
    },
  );
}


  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }
}
