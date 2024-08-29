// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/subtelas/profissionais/speaker.dart';

class TutorialCarousel extends StatefulWidget {
  final String username;
  const TutorialCarousel({super.key, required this.username});

  @override
  _TutorialCarouselState createState() => _TutorialCarouselState();
}

class _TutorialCarouselState extends State<TutorialCarousel> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.asset(imagePath),
          ),
        );
      },
    );
  }

  void _finish() async {
    var users = FirebaseFirestore.instance.collection('users');
    var querySnapshot = await users.where('email', isEqualTo: widget.username).get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.update({'viu-tutorial': true});
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(username: widget.username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tutorialItems = [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logoInjectPreta.jpeg', fit: BoxFit.cover),
          const SizedBox(height: 20),
          const Text(
            'Bem-vindo ao nosso Speaker!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 236, 63, 121)),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Descubra como a nossa tecnologia pode transformar sua prática estética! Tire todas suas dúvidas e melhore seu dia a dia com respostas precisas e rápidas.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => _showImageDialog('assets/images/print-produto.jpg'),
                child: Image.asset('assets/images/print-produto.jpg', fit: BoxFit.fitWidth,),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Encontre os melhores produtos!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 236, 63, 121),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Peça sugestões ao Speaker e descubra os produtos ideais para obter resultados impressionantes em seus pacientes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showImageDialog('assets/images/print-tecnicas1.jpg'),
                      child: Image.asset('assets/images/print-tecnicas1.jpg'),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showImageDialog('assets/images/print-tecnicas2.jpg'),
                      child: Image.asset('assets/images/print-tecnicas2.jpg'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dúvidas técnicas?\nNós temos as respostas!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 236, 63, 121)),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'O Speaker está aqui para te apoiar com questões técnicas, desde métodos de aplicação até técnicas avançadas, para que você trabalhe com confiança.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    ];

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
          if (_current == tutorialItems.length - 1)
            TextButton(
              onPressed: _finish,
              child: const Text(
                'Concluir',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _finish,
              child: const Text(
                'Pular Tutorial',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
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
                            : const Color.fromARGB(255, 236, 63, 121))
                        .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
 