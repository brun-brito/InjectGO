// ignore_for_file: file_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'loginScreen.dart';
import 'cadastroScreen.dart';
import 'package:inject_go/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InjectGO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Future<void> _showTermsDialog(BuildContext context) async {
    String terms;
    try {
      terms = await rootBundle.loadString('assets/terms/termoServico.txt');
    } catch (e) {
      terms = 'Não foi possível carregar os termos de serviço.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termos de Serviço InjectGO'),
          content: SingleChildScrollView(
            child: Text(terms),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

void _showEligibilityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Você mora em Fortaleza?"),
          actions: <Widget>[
            TextButton(
              child: Text("Sim"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
            ),
            TextButton(
              child: Text("Não"),
              onPressed: () {
                Navigator.of(context).pop();
                // Exibe a mensagem de ineligibilidade
                _showIneligibilityMessage();
              },
            ),
          ],
        );
      },
    );
  }

  void _showIneligibilityMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Aviso"),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
              Text(
                "Infelizmente o nosso app não chegou na sua região ainda 😭\nMas não se preocupe! Nós iremos te mandar um e-mail, assim que o App estiver disponível para te atender 🥳",
                style: TextStyle(
                  fontSize: 20, // Aumente o valor de fontSize conforme necessário
                ),
              ),
            ]
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), //seta pra voltar
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
        ),
        title: const Text('Seja bem vindo(a)!'), //título da pag
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
         child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment:
              Alignment.topCenter, 
              child: Image.asset(
                'assets/images/logoInject.jpeg',  //logo da marca
                fit: BoxFit
                    .fitWidth, 
              ),
            ),

            const Text(
              'Crie sua conta', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16.0),
            TextFormField(
              decoration: 
                const InputDecoration(
                  labelText: 'Digite seu melhor e-mail',
                  prefixIcon: Icon(Icons.mail),
                ),

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu e-mail';
                }
                return null;
              },
            ),

            ElevatedButton(
              child: const Text('Continue'),
              onPressed: _showEligibilityDialog,
            ),

            const SizedBox(height: 16.0),
            RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Color.fromARGB(255, 64, 62, 62), fontSize: 14.0),
              children: <TextSpan>[
                const TextSpan(text: 'Ao se inscrever, você concorda com os termos da InjectGO '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    _showTermsDialog(context);
                  },
                ),
              ],
            ),
          ),
          
            const SizedBox(height: 25.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Já possui conta? '),
                InkWell(
                  child: const Text(
                    'Log in',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold,decoration: TextDecoration.underline),
                  ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}