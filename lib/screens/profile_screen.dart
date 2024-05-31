// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/subtelas/arquivos.dart';
import 'package:inject_go/subtelas/editar_dados.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/screens/login_screen.dart';
// import 'package:inject_go/subtelas/token.dart';
import 'package:inject_go/google-maps/mapa.dart';
import 'package:intl/intl.dart'; 
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../subtelas/leitor_qrcode.dart';

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
  String cpf = ""; 
  String bio = ""; 
  String dateFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String? _imageUrl;
  bool _isLoading = false; 
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil do Usuário"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildUserProfile(),
    );
  }

  Widget buildUserProfile() {
    return ListView(
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
                onTap: () => _showSelectionDialog(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 90,
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8), 
                decoration: BoxDecoration(
                  border: Border.all(color: /*const Color(0xFFf6cbc2)*/Colors.pink),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.edit, color:  /*Color(0xFFf6cbc2)*/ Colors.pink),
                  label: const Text('Editar perfil', style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditUserProfileScreen(username: widget.username)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8), 
                decoration: BoxDecoration(
                  color: const /*Color(0xFFf6cbc2),*/ Color.fromARGB(255, 236, 63, 121),
                  border: Border.all(color: /*const Color(0xFFf6cbc2)*/Colors.pink),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.shopify_outlined, color: Colors.white),
                  label: const Text('InjectBank', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                     mensagemEmBreve('InjectBank');
                    },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(8), // Margem interna ao redor do ícone e do texto
                ),
                ),
                  ),
                ),
              ],
            ),
          ),

          // const Divider(),
          Center(
            child: Container(
              margin: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(10.0), 
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Arquivos(username: widget.username))
                        );
                      },
                      icon: const Icon(Icons.folder, color: Colors.grey), 
                      label: const Text('Arquivos', style: TextStyle(color: Colors.black)), 
                    ),
                    const VerticalDivider(),
                    TextButton.icon(
                      onPressed: () {
                        mensagemEmBreve('ID facial');
                      },
                      icon: Image.asset('assets/images/faceId.png', width: 24, height: 24,),
                      label: const Text('ID facial', style: TextStyle(color: Colors.black)),
                    ),
                    const VerticalDivider(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapScreen())
                        );
                      },
                      icon: const Icon(Icons.location_on, color: Colors.grey), 
                      label: const Text('Mercado', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Banner:
          SizedBox(
            height: 180, 
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2, // tamanho do carrossel
              onPageChanged: (int page) {
                if (page == 1) {
                  // entrou na página do vídeo
                  if (_videoPlayerController != null && !_videoPlayerController!.value.isPlaying) {
                    _videoPlayerController!.play();
                  }
                } else if (_currentPage == 1) {
                  // saindo da página do vídeo
                  if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
                    _videoPlayerController!.pause();
                  }
                }
                setState(() {
                  _currentPage = page;  
                });
              },
              itemBuilder: (_, index) {
                return index == 0 ? buildFirstPage() : buildSecondPage(); 
              },
            ),
          ),
          if (_currentPage == 1) 
            const SizedBox(height: 5),
          Center(child:buildPageIndicator()),         
          const SizedBox(height: 10),

          // Token e Sair
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90), 
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), 
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
              ),
              onPressed: () => Navigator.push(
                context,
                  MaterialPageRoute(builder: (context) => QRCodePage(username: widget.username))
                // se for usar o TOKEN use essa classe: 'TOTPDisplay(username: widget.username))'
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner),
                  SizedBox(width: 8),  
                  Text('Validar QR Code'),
                ],
              ),
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
  
  void mensagemEmBreve(String titulo){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo, style: const TextStyle(fontSize: 24,fontWeight: FontWeight.bold)), 
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
    _initializeVideoPlayer();
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
          cpf = "${userProfile['cpf']}";
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
        .ref('$nome-$cpf/$filePath')
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
    showModalBottomSheet<void>(
      context: context,
      // isDismissible: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                  ),
                ],
              ),
              Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Selecionar da galeria'),
                    onTap: () async {
                      Navigator.pop(context);
                      setLoading(true);
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        File imageFile = File(pickedFile.path);
                        uploadSelfie(imageFile);
                      } else {
                        setLoading(false);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Tirar uma foto'),
                    onTap: () async {
                      Navigator.pop(context);
                      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        File imageFile = File(pickedFile.path);
                        setLoading(true);
                        uploadSelfie(imageFile);
                      } else {
                        setLoading(false);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
        .ref('$nome-$cpf/$filePath')
        .putFile(imageFile);

      String imageUrl = await FirebaseStorage.instance
        .ref('$nome-$cpf/$filePath')
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
        .ref('$nome-$cpf/$fileName')
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

  void _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.asset('assets/videos/video_merz.mp4');
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 9 / 16, 
        autoPlay: false,
        looping: true,
        autoInitialize: true,
      );
      setState(() {});
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao inicializar o vídeo: $e"))
        );
      }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget buildFirstPage() {
    return Container(
      padding: const EdgeInsets.only(left: 15),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const /*Color(0xFFf6cbc2)*/ Color.fromARGB(255, 236, 63, 121),
        // border: Border.all(color: Colors.pink),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Sua jornada\ncomeça aqui.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Apenas escolha onde\ne quando',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Image.asset(
              'assets/images/merz.jpeg',
                  height: 140,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }

Widget buildSecondPage() {
  return Padding(
    padding: const EdgeInsets.only(left: 70, right: 70), 
    child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized ? Chewie(
      controller: _chewieController!,
    ) : const Center(child: CircularProgressIndicator()),
  );
}

  Widget buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(2, (index) => buildIndicator(index == _currentPage)),
    );
  }

  Widget buildIndicator(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const /*Color(0xFFf6cbc2)*/ Color.fromARGB(255, 236, 63, 121) : Colors.grey,
      ),
    );
  }

  void _showSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Foto do Perfil"),
        content: const Text("Escolha a ação desejada:"),
        actions: <Widget>[
          TextButton(
            child: const Text("Remover Foto"),
            onPressed: () {
              Navigator.of(context).pop(); 
              removeSelfie(); 
            },
          ),
          TextButton(
            child: const Text("Adicionar/Trocar Foto"),
            onPressed: () {
              Navigator.of(context).pop(); 
              _pickImage();
            },
          ),
          TextButton(
            child: const Text("Cancelar"),
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