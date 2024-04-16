// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: RandomNumberScreen(),
//     );
//   }
// }

// class RandomNumberScreen extends StatefulWidget {
//   @override
//   _RandomNumberScreenState createState() => _RandomNumberScreenState();
// }

// class _RandomNumberScreenState extends State<RandomNumberScreen> {
//   String _randomNumber = '';
//   late Timer _timer;
//   double _progress = 0;  // Progresso do indicador de carregamento

//   @override
//   void initState() {
//     super.initState();
//     _generateRandomNumber();
//     _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
//       setState(() {
//         _progress += 1/30;  // Atualiza o progresso a cada segundo
//         if (_progress >= 1) {
//           _generateRandomNumber();
//           _progress = 0;  // Reinicia o progresso após 30 segundos
//         }
//       });
//     });
//   }

//   void _generateRandomNumber() {
//     final randomNumber = Random().nextInt(900000) + 100000; // Garante um número de 6 dígitos
//     setState(() {
//       _randomNumber = randomNumber.toString();
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel(); // evitar vazamento de memória
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gerador de Token Único'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               _randomNumber,
//               style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 24),  // Espaçamento entre o número e o indicador
//             CircularProgressIndicator(
//               value: _progress,  // Vincula o valor do progresso ao indicador
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//             ),
//             SizedBox(height: 8),  // Espaçamento
//             Text('Atualizando token em ${(30 - _progress * 30).round()} segundos'),
//           ],
//         ),
//       ),
//     );
//   }
// }