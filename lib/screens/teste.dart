import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _choice = '';

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Você mora em Fortaleza?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: const Text('Sim'),
                value: 'sim',
                groupValue: _choice,
                onChanged: (value) {
                  setState(() {
                    _choice = value!;
                    Navigator.pop(context); // Fecha o dialog
                    // Aqui, você poderia navegar para outra página ou exibir mais conteúdo
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Não'),
                value: 'não',
                groupValue: _choice,
                onChanged: (value) {
                  setState(() {
                    _choice = value!;
                    Navigator.pop(context); // Fecha o dialog
                    _showMessage();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage() {
    if (_choice == 'não') {
      final snackBar = SnackBar(
        content: Text('Infelizmente você não está apto para nosso app ainda.\nMas não se preocupe! Nós iremos te mandar um e-mail, para quando o nosso App estiver disponível para atender sua região :)'),
        duration: Duration(seconds: 15),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demonstração'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showDialog,
          child: Text('Clique aqui'),
        ),
      ),
    );
  }
}
