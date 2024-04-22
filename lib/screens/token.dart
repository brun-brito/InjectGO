import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TOTPDisplay(),
    );
  }
}

class TOTPDisplay extends StatefulWidget {
  @override
  _TOTPDisplayState createState() => _TOTPDisplayState();
}

class _TOTPDisplayState extends State<TOTPDisplay> {
  String _token = '';
  int _secondsLeft = 30;
  double _progress = 1.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    exibeToken();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          _progress = _secondsLeft / 30.0;
        }
        if (_secondsLeft == 0) {
          exibeToken();
        }
      });
    });
  }

  void exibeToken() async {
    var url = Uri.parse('https://injectgo.rj.r.appspot.com/generate-totp');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      setState(() {
        _token = jsonResponse['token'];
        _secondsLeft = jsonResponse['tempoRestante'];
        _progress = _secondsLeft / 30.0;
      });
    } else {
      setState(() {
        _token = 'Erro ao gerar token: ${response.statusCode}';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerador de Token Único'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_token',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>( Color.fromARGB(255, 236, 63, 121),),
            ),
            SizedBox(height: 8),
            Text('Faltam $_secondsLeft segundos para expirar', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
