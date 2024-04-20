import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'screens/teste.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Protótipo InjectGO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    //double larguraTela = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),  
                  child: Image.asset(
                  'assets/images/logoInject.jpeg',
                  width: 200,
                  height: 90,
                  fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0), // Espaçamento entre as imagens
              child: Image.asset(
                'assets/images/inject.jpeg',
                fit: BoxFit.fitWidth,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0), // Aumenta o recuo lateral
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Receba pacientes agendados e\n compre produtos sem \ncomplicações',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32), // Espaço antes do botão
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.white,
                    ),

                      onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  const WelcomePage() /*RegistrationScreen()*/),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: <Widget>[
                        Text('Iniciar '),
                        Icon(Icons.arrow_forward), 
                      
                      ],
                    ),
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