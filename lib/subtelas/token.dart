// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TOTPDisplay extends StatefulWidget {
  final String username;

  const TOTPDisplay({super.key, required this.username});

  @override
  _TOTPDisplayState createState() => _TOTPDisplayState();
}

class _TOTPDisplayState extends State<TOTPDisplay> {
  String _token = '';
  String _user = '';
  int _secondsLeft = 30;
  double _progress = 1.0;
  late Timer _timer;
  bool _isLoading = true;
  bool _isOk = false;

  Future<void> getUser() async{
    try {
      var userProfileQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.username)
        .limit(1)
        .get();

      if (userProfileQuery.docs.isNotEmpty) {
        var userProfile = userProfileQuery.docs.first;
        _user = userProfile['usuario'];
      }
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao buscar usuário: $e"))
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await getUser(); 
    exibeToken(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          _progress = _secondsLeft / 30.0;
        }
        if (_secondsLeft == 0) {
          getUser();
          exibeToken();
        }
      });
    });
  }


  void exibeToken() async {
    setState(() {
      _isLoading = true; 
    });
    var url = Uri.parse('${dotenv.env['API_URL']}/generate-totp?user=$_user');
    // var url = Uri.parse('http://10.0.2.2:8080/generate-totp?user=$_user'); 
    var response = await http.get(url, headers: {'x-api-key': 'injectgoinjetaveis'});
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      setState(() {
        _isOk = true; 
        _token = jsonResponse['token'];
        _secondsLeft = jsonResponse['tempoRestante'];
        _progress = _secondsLeft / 30.0;
      });
    } else {
      setState(() {
        _isOk = false; 
        // _token = 'Erro ao gerar token, tente novamente mais tarde!'; //: ${response.statusCode}';
      });
    }
    _isLoading = false; 
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
        title: const Text('Token'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 236, 63, 121),
                ),
              )

            else if (_isOk)...[
              Text(
                'Token único para o usuário "$_user":',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _token,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 236, 63, 121),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Falta(m) $_secondsLeft segundo(s) para expirar',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ]

            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    SizedBox(height: 8),
                    Text(
                      'Erro ao gerar token,\ntente novamente mais tarde!',
                      style: TextStyle(fontSize: 25),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}