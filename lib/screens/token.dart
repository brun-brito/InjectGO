import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokenScreen extends StatefulWidget {
  @override
  _TokenScreenState createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final TextEditingController _userIdController = TextEditingController();
  String _token = '';

  Future<void> generateToken() async {
    var response = await http.post(
      Uri.parse('http://your-server-ip:3000/generate-token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userId': _userIdController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _token = jsonDecode(response.body)['token'];
      });
    } else {
      print('Failed to generate token');
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
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(hintText: 'Enter your User ID'),
            ),
            ElevatedButton(
              onPressed: generateToken,
              child: Text('Generate Token'),
            ),
            Text('Your token: $_token'),
          ],
        ),
      ),
    );
  }
}
