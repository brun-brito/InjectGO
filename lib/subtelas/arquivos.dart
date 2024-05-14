// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Arquivos extends StatefulWidget {
  final String username;

  const Arquivos({super.key, required this.username});

  @override
  _ArquivosState createState() => _ArquivosState();
}

class _ArquivosState extends State<Arquivos> {
  late List<Map<String, String>> documents;
  bool isLoading = true;  
  String nome = '';
  bool showError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
  }

Future<void> fetchImageUrls() async {
  setState(() {
    isLoading = true;
    showError = false;  
  });
  try {
    var userProfileQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: widget.username) 
      .limit(1)
      .get();

    if (userProfileQuery.docs.isNotEmpty) {
      var userProfile = userProfileQuery.docs.first;
      nome = userProfile['nome'];
      // var sobrenome = userProfile['sobrenome'];
      var cpf = userProfile['cpf'];
      // var priSobr = sobrenome.split(' ')[0];
      var fullName = "$nome-$cpf";

      var storageRef = FirebaseStorage.instance.ref().child(fullName);
      var listResult = await storageRef.listAll();

      var urls = await Future.wait(listResult.items.where((item) => !item.name.startsWith('foto')).map((item) async {
        String title = item.name.replaceAll('-', ' ').split('.')[0];

        if (title.toLowerCase().startsWith('selfie')) {
          title = 'Selfie com carteirinha:';
        } else if (title.toLowerCase().startsWith('certidao')) {
          title = 'Certidão de Regularidade Técnica:';
        }

        return {
          'title': title,
          'url': await item.getDownloadURL()
        };
      }));

      setState(() {
        documents = urls;
        isLoading = false;
      });
    } 
  } catch (e) {
      setState(() {
        isLoading = false;
        showError = true; 
        errorMessage = "Falha ao carregar documentos: $e";
      });
    }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Arquivos de $nome'),
    ),
    body: Stack(
      children: [
        if (!isLoading && documents.isEmpty)
          const Center(
            child: Text('Nenhum documento encontrado para o usuário.'),
          ),

        if (!isLoading && showError)
          Center(
            child: Text('Falha ao carregar documentos: $errorMessage'),
          ),

        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),

        if (!isLoading && documents.isNotEmpty)
          ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(documents[index]['title']!, style: const TextStyle(fontSize: 17)),
                subtitle: AspectRatio(
                  aspectRatio: 1, 
                  child: Image.network(
                    documents[index]['url']!,
                    fit: BoxFit.cover 
                  ),
                ),
                contentPadding: const EdgeInsets.all(10.0),
              );
            },
          ),
      ],
    ),
  );
}
}