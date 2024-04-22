// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/screens/editar_dados.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/screens/login_screen.dart';
import 'package:inject_go/screens/token.dart';
import 'package:intl/intl.dart'; 

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String prefixo = "";
  String fullName = ""; 
  String bio = ""; 
  String dateFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String? _imageUrl;
  bool _isLoading = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil do Usuário"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : buildUserProfile(),
    );
  }

  Widget buildUserProfile() {
    // This method returns the ListView that was originally directly in the build method
    return ListView(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.all(20),
            child: GestureDetector(
                onTap: () => _showSelectionDialog(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null ? const Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ) : null,
                    ),
                    if (_imageUrl == null)
                      const Positioned(
                        bottom: 45,
                        child: Text(
                          'Clique para adicionar foto',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
            ),
        ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), 
              child: Text(
                "$prefixo $fullName", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), 
              child: Text(
                bio, // Dynamic bio
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 55),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink), 
                    borderRadius: BorderRadius.circular(8), 
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.pink),
                    label: const Text('Editar perfil'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditUserProfileScreen(username: widget.username)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(8), 
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 236, 63, 121),
                    border: Border.all(color: Colors.pink), 
                    borderRadius: BorderRadius.circular(8), 
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.shopify_outlined, color: Colors.white),
                    label: const Text('InjectBank', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("InjectBank", style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)), 
                            content: const Text(
                              "Em breve novidades para você, profissional que deseja facilitar seu dia a dia.",
                              style: TextStyle(fontSize: 18), 
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("OK", style: TextStyle(fontSize: 18)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(8), // Margem interna ao redor do ícone e do texto
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Arquivo'),
            onTap: () {
              // Navigate to Arquivo
            },
          ),ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Arquivo'),
            onTap: () {
              // Navigate to Arquivo
            },
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('ID facial'),
            onTap: () {
              // Navigate to ID facial
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Mercado'),
            onTap: () {
              // Navigate to Mercado
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 90), // Adjust the padding as needed for your layout
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Border radius
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Button padding
              ),onPressed: () =>  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TOTPDisplay())
                  ),
              child: const Text('Gerar token de compra'),
            ),
          ),
          Center(
            child: TextButton(
                onPressed: () => logout(context),
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }
  
  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    setLoading(true);
    try {
      var userProfileQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.username)
        .limit(1)
        .get();

      if (userProfileQuery.docs.isNotEmpty) {
        var userProfile = userProfileQuery.docs.first;
        setState(() {
          if (userProfile['sexo'] == 'Feminino')
            prefixo = 'Dra.';
          else if (userProfile['sexo'] == 'Masculino')
            prefixo = 'Dr.';
          fullName = "${userProfile['nome']} ${userProfile['sobrenome']}";
          if(userProfile['bio'] == "")
            bio = 'Adicione sua biografia em Editar perfil';
          else
            bio = userProfile['bio'];
        });
        loadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar dados do usuário: $e"))
      );
    }
    setLoading(false);
  }

  Future<void> loadImage() async {
    setLoading(true);
    if (fullName.isEmpty) {
      setLoading(false);
      return;
    }
    try {
      String nome = fullName.split(' ')[0];
      String sobrenome = fullName.split(' ')[1];
      String filePath = 'foto-perfil-$nome-$sobrenome.jpg';
      String imageUrl = await FirebaseStorage.instance
        .ref('$nome-$sobrenome/$filePath')
          .getDownloadURL();

      setState(() {
        _imageUrl = imageUrl;
      });
    }on FirebaseException catch (e) {
    if (e.code == 'object-not-found') {
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar a imagem de perfil: $e"))
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ocorreu um erro inesperado: $e"))
    );
  }
  setLoading(false);
}

  Future<void> _pickImage() async {
    setLoading(true);
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      uploadSelfie(imageFile);
    } else {
      setLoading(false);
    }
  }

  Future<void> uploadSelfie(File imageFile) async {
    if (fullName.isEmpty) {
      setLoading(false);
      return;
    }
    try {
      String nome = fullName.split(' ')[0];
      String sobrenome = fullName.split(' ')[1];
      String filePath = 'foto-perfil-$nome-$sobrenome.jpg';
      await FirebaseStorage.instance
        .ref('$nome-$sobrenome/$filePath')
        .putFile(imageFile);

      String imageUrl = await FirebaseStorage.instance
        .ref('$nome-$sobrenome/$filePath')
        .getDownloadURL();
      setState(() {
        _imageUrl = imageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto de perfil atualizada!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar foto de perfil: $e'))
      );
    }
    setLoading(false);
  }

  Future<void> removeSelfie() async {
    setLoading(true);
    if (_imageUrl == null) {
      setLoading(false);
      return;
    }

    try {
      String nome = fullName.split(' ')[0];
      String sobrenome = fullName.split(' ')[1];
      String fileName = 'foto-perfil-$nome-$sobrenome.jpg';

      await FirebaseStorage.instance
        .ref('$nome-$sobrenome/$fileName')
        .delete(); 
      setState(() {
        _imageUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto de perfil removida!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover foto de perfil: $e'))
      );
    }
    setLoading(false);
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginForm()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Foto do Perfil"),
        content: Text("Escolha a ação desejada:"),
        actions: <Widget>[
          TextButton(
            child: Text("Remover Foto"),
            onPressed: () {
              Navigator.of(context).pop(); 
              removeSelfie(); 
            },
          ),
          TextButton(
            child: Text("Adicionar/Trocar Foto"),
            onPressed: () {
              Navigator.of(context).pop(); 
              _pickImage();
            },
          ),
          TextButton(
            child: Text("Cancelar"),
            onPressed: () {
              Navigator.of(context).pop(); 
            },
          ),
        ],
      );
    },
  );
}

}