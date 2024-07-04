// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/subtelas/speaker.dart';

class TutorialCarousel extends StatefulWidget {
  final String username;
  const TutorialCarousel({super.key, required this.username});

  @override
  _TutorialCarouselState createState() => _TutorialCarouselState();
}

class _TutorialCarouselState extends State<TutorialCarousel> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

 final List<Widget> tutorialItems = [
    const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image.network('https://via.placeholder.com/300x200', fit: BoxFit.cover),
        SizedBox(height: 20),
        Text(
          'Bem-vindo ao nosso Speaker!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Descubra como a nossa tecnologia pode transformar sua prática estética! Tire todas suas dúvidas e melhore seu dia a dia com respostas precisas e rápidas.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
    const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image.network('https://via.placeholder.com/300x200', fit: BoxFit.cover),
        SizedBox(height: 20),
        Text(
          'Encontre os melhores produtos!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Peça sugestões ao Speaker e descubra os produtos ideais para obter resultados impressionantes em seus pacientes.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
    const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image.network('https://via.placeholder.com/300x200', fit: BoxFit.cover),
        SizedBox(height: 20),
        Text(
          'Dúvidas técnicas?\nNós temos as respostas!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'O Speaker está aqui para te apoiar com questões técnicas, desde métodos de aplicação até técnicas avançadas, para que você trabalhe com confiança.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
    const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image.network('https://via.placeholder.com/300x200', fit: BoxFit.cover),
        SizedBox(height: 20),
        Text(
          'Novidade chegando...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Em breve, envie fotos de seus pacientes e receba conselhos personalizados para alcançar a harmonização facial perfeita!',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  ];
      
  void _finish() async{
    var users = FirebaseFirestore.instance.collection('users');
      var querySnapshot = await users.where('email', isEqualTo: widget.username).get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'viu-tutorial': true});
      }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatPage(username: widget.username)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Speaker'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CarouselSlider(
              items: tutorialItems,
              carouselController: _controller,
              options: CarouselOptions(
                height: 400,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: tutorialItems.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_current == tutorialItems.length - 1)
            ElevatedButton(
              onPressed: _finish,
              child: const Text('Concluir'),
            )
          else
            ElevatedButton(
              onPressed: _finish,
              child: const Text('Pular'),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
