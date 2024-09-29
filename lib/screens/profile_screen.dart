// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/subtelas/profissionais/mercado/main_screen.dart';
// import 'package:inject_go/subtelas/profissionais/minhas_compras.dart';
import 'package:inject_go/subtelas/profissionais/speaker.dart';
import 'package:inject_go/subtelas/profissionais/arquivos.dart';
import 'package:inject_go/subtelas/profissionais/editar_dados.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/screens/login_screen.dart';
import 'package:inject_go/google-maps/mapa.dart';
import 'package:inject_go/subtelas/profissionais/tutorial_speaker.dart';
import 'package:intl/intl.dart'; 
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:inject_go/subtelas/profissionais/leitor_qrcode.dart';

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
  bool? viuTutorial; 
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String userId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Perfil do Usuário"),
        centerTitle: true,
        automaticallyImplyLeading: false
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)))
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.pink),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit, color: Colors.pink),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Editar perfil',
                              style: TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditUserProfileScreen(username: widget.username)),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.mic, color: Colors.white),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Speaker',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          onPressed: () async {
                            await getTutorial();
                            if (viuTutorial != null && viuTutorial!) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(username: widget.username, nome: fullName.split(' ')[0], cpf: cpf),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TutorialCarousel(username: widget.username),
                                ),
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.shopify_outlined, color: Colors.white),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'InjectBank',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          onPressed: () {
                            mensagemEmBreve('InjectBank');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 236, 63, 121),
                          border: Border.all(color: Colors.pink),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          icon: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.0,
                                ) // Exibe o indicador de carregamento quando está carregando
                              : const Icon(Icons.shopping_cart, color: Colors.white), // Ícone normal
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Mercado',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null // Desativa o botão enquanto está carregando
                              : () {
                                  _goToMainScreen(context); // Função para ir ao mercado
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      icon: Image.asset('assets/images/faceId.png', width: 24, height: 24),
                      label: const Text('ID facial', style: TextStyle(color: Colors.grey)),
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
                      label: const Text('Localização', style: TextStyle(color: Colors.black)),
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

  Future<void> getTutorial() async {
    var userProfileQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (userProfileQuery.docs.isNotEmpty) {
      var userProfile = userProfileQuery.docs.first;
      setState(() {
        viuTutorial = userProfile['viu-tutorial'];
      });
    }
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
          userId = userProfile.id;
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
          viuTutorial = userProfile['viu-tutorial'];
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
      String filePath = 'profissionais/$nome-$cpf/foto-perfil-$nome.jpg';
      String imageUrl = await FirebaseStorage.instance
        .ref(filePath)
        .getDownloadURL();

      setState(() {
        _imageUrl = imageUrl;
      });
    } on FirebaseException catch (e) {
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
      String filePath = 'profissionais/$nome-$cpf/foto-perfil-$nome.jpg';
      await FirebaseStorage.instance
        .ref(filePath)
        .putFile(imageFile);

      String imageUrl = await FirebaseStorage.instance
        .ref(filePath)
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
      String fileName = 'profissionais/$nome-$cpf/foto-perfil-$nome.jpg';

      await FirebaseStorage.instance
        .ref(fileName)
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
    try {
      // Obtenha os tokens FCM (para Android) e APNS (para iOS)
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

      if (userId.isNotEmpty) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data();

          // Verifique se há campo 'tokens' no documento do usuário
          if (data != null && data.containsKey('tokens')) {
            List<dynamic> existingTokens = data['tokens'];

            // Atualize a lista de tokens para remover
            List<dynamic> updatedTokens = existingTokens.where((token) {
              bool shouldRemove = false;

              // Remover o FCM Token, se existir
              if (fcmToken != null && token['fcmToken'] == fcmToken) {
                shouldRemove = true;
                debugPrint("Token FCM encontrado e removido.");
              }

              // Remover o APNS Token, se existir
              if (apnsToken != null && token['apnsToken'] == apnsToken) {
                shouldRemove = true;
                debugPrint("Token APNS encontrado e removido.");
              }

              return !shouldRemove; // Retorna apenas os tokens que não devem ser removidos
            }).toList();

            // Atualiza o documento Firestore com a nova lista de tokens
            await docRef.update({
              'tokens': updatedTokens,
            });

            debugPrint("Tokens removidos com sucesso.");
          } else {
            debugPrint("Campo 'tokens' não encontrado no documento do usuário.");
          }
        } else {
          debugPrint("Documento do usuário não encontrado.");
        }
      }

      // Fazer o logout do FirebaseAuth
      await FirebaseAuth.instance.signOut();

      // Navegar para a tela de login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginForm()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Exibir um erro se houver falha no logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
      );
    }
  }

  void _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.asset('assets/videos/video_merz.mp4');
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: false,
        looping: true,
        autoInitialize: true,
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao inicializar o vídeo: $e")),
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
      padding: const EdgeInsets.all(8.0),
    child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized ? Chewie(
      controller: _chewieController!,
    ) : const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121))),
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('O serviço de localização está desativado.');
    }

    // Verifica o status das permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('É preciso autorizar sua localização, para trazermos as lojas mais próximas de você!');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Você negou o uso de sua localização algumas vezes. Por favor, vá até as configurações de seu telefone e habilite manualmente.');
    }

    // Obtém a posição atual do dispositivo
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Função que trata o carregamento e navegação para a página de Mercado
  void _goToMainScreen(BuildContext context) async {
    setState(() {
      _isLoading = true; // Inicia o carregamento
    });

    try {
      // Obtém a localização atual do profissional
      Position position = await _determinePosition();

      // Navega para a tela de Mercado passando a posição como parâmetro
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(userPosition: position, email: widget.username),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter a localização: $e'),duration: const Duration(seconds: 8)),
      );
    } finally {
      setState(() {
        _isLoading = false; // Finaliza o carregamento
      });
    }
  }

}