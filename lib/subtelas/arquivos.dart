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

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
  }

Future<void> fetchImageUrls() async {
  setState(() {
    isLoading = true;  // Inicia o loading antes de começar a operação
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
      var sobrenome = userProfile['sobrenome'];
      var priSobr = sobrenome.split(' ')[0];
      var fullName = "$nome-$priSobr";

      var storageRef = FirebaseStorage.instance.ref().child(fullName);
      var listResult = await storageRef.listAll();

      var urls = await Future.wait(listResult.items.where((item) => !item.name.startsWith('foto')).map((item) async {
        return {
          'title': item.name.replaceAll('-', ' ').split('.')[0],
          'url': await item.getDownloadURL()
        };
      }));

      setState(() {
        documents = urls;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum documento encontrado para o usuário."))
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Falha ao carregar documentos: $e"))
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arquivos de $nome'),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(documents[index]['title']!),
                subtitle: AspectRatio(
                  aspectRatio: 1, 
                  child: Image.network(
                    documents[index]['url']!,
                    fit: BoxFit.cover 
                  ),
                ),
                contentPadding: EdgeInsets.all(10.0),
              );
            },
          ),
    );
  }
}