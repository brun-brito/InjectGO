import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: TokenPage(),
  ));
}

class TokenPage extends StatefulWidget {
  @override
  _TokenPageState createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  String _message = 'Clique para gerar um token';

  void _generateToken() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/random-number'));
      if (response.statusCode == 200) {
        setState(() {
          _message = 'Token gerado: ${response.body}';
        });
      } else {
        setState(() {
          _message = 'Erro ao gerar token: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Token Generator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_message, // Exibe a mensagem do estado
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateToken,
              child: Text('Gerar Token'),
            ),
          ],
        ),
      ),
    );
  }
}
