import 'package:flutter/material.dart';
import 'screens/teste.dart'; // Ajuste o caminho de importação conforme necessário

void main() {
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
        // Permite rolagem caso o conteúdo exceda a altura da tela
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch, // Estica os filhos horizontalmente
          children: <Widget>[
            Align(
              alignment:
              Alignment.topCenter, // Alinha a imagem ao topo centralizado
              child: Image.asset(
                'assets/images/logoInject.jpeg',
                fit: BoxFit
                    .fitWidth, // Mantém as proporções originais, ajustando a largura
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16.0), // Espaçamento entre as imagens
              child: Image.asset(
                'assets/images/inject.jpeg',
                //width: larguraTela * 0.8, // 80% da largura da tela
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
                        MaterialPageRoute(builder: (context) =>  HomePage()),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Minimiza o tamanho da Row baseado nos filhos
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