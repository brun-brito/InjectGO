import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TOTPDisplay extends StatefulWidget {
  final String username;

  const TOTPDisplay({Key? key, required this.username}) : super(key: key);

  @override
  _TOTPDisplayState createState() => _TOTPDisplayState();
}

class _TOTPDisplayState extends State<TOTPDisplay> {
  String _token = '';
  String _user = '';
  int _secondsLeft = 30;
  double _progress = 1.0;
  late Timer _timer;

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
    await getUser(); // Garante que o usuário seja recuperado primeiro
    exibeToken(); // Depois que o usuário é recuperado, exibe o token
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    var url = Uri.parse('https://injectgo.rj.r.appspot.com/generate-totp?user=$_user');
    // var url = Uri.parse('http://10.0.2.2:8080/generate-totp?user=$_user'); 
    var response = await http.get(url, headers: {'x-api-key': 'injectgoinjetaveis'});
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
