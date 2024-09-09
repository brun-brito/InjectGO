// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/mercado_pago/mensalidade_distribuidor.dart';
import 'package:inject_go/mercado_pago/oauth_mp.dart';
import 'package:inject_go/screens/login_screen.dart';
import 'package:inject_go/subtelas/distribuidores/cadastra_produto.dart';
import 'package:inject_go/subtelas/distribuidores/meus_produtos.dart';

class ProfileScreenDistribuidor extends StatefulWidget {
  final String username;

  const ProfileScreenDistribuidor({super.key, required this.username});

  @override
  _ProfileScreenDistribuidorState createState() => _ProfileScreenDistribuidorState();
}

class _ProfileScreenDistribuidorState extends State<ProfileScreenDistribuidor> {
  final ImagePicker _picker = ImagePicker();
  String companyName = "";
  String? _imageUrl;
  String razaoSocialCnpj = '';
  String email = '';
  bool _isLoading = false;
  bool _isPaymentUpToDate = false;
  bool _hasPaymentData = false;
  bool _isAuthorized = false;
  Map<String, dynamic>? _credenciaisMp;
  
  @override
  void initState() {
    super.initState();
    fetchDistributorProfile();
  }

  Future<void> fetchDistributorProfile() async {
    setLoading(true);
    try {
      var distribuidorSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .where('email', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (distribuidorSnapshot.docs.isNotEmpty) {
        var distribuidorData = distribuidorSnapshot.docs.first.data();
        razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';
        email = distribuidorData['email'];
        companyName = distribuidorData['razao_social'];

        // Verificar se o pagamento está em dia
        setState(() {
          _isPaymentUpToDate = distribuidorData['pagamento_em_dia'] ?? false;
          _hasPaymentData = distribuidorData.containsKey('dados_pagamento');
          _credenciaisMp = distribuidorData['credenciais_mp'];  // Verifica se as credenciais do MP estão salvas
          _isAuthorized = _credenciaisMp != null;
        });

        // Tentar carregar a foto do perfil
        String fileName = 'distribuidores/$razaoSocialCnpj/foto-perfil.jpg';
        try {
          String imageUrl = await FirebaseStorage.instance.ref(fileName).getDownloadURL();
          setState(() {
            _imageUrl = imageUrl;
          });
        } catch (e) {
          setState(() {
            _imageUrl = null;
          });
        }
      } else {
        throw 'Distribuidor não encontrado';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }
    setLoading(false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Perfil do Distribuidor"),
        centerTitle: true,
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
                  child: _imageUrl == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Color.fromARGB(255, 117, 117, 117),
                        )
                      : null,
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
            child: Text('Seja bem vindo(a), $companyName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (_isPaymentUpToDate && !_isAuthorized)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MercadoPagoOAuthScreen(username: razaoSocialCnpj, userEmail: email),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock, color: Colors.white),
                  label: const Text('Vincular Mercado Pago', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(200, 50), // Define o tamanho menor do botão
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Para criar e postar produtos, você precisa vincular sua conta do Mercado Pago. '
                    'As vendas dos produtos serão processadas através dessa conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        icon: Icon(Icons.add_business, color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cadastrar Produto',
                            style: TextStyle(
                              color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.black : Colors.grey, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onPressed: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? () => _navigateToProductRegistration(context) : null,
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
                        border: Border.all(color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        icon: Icon(Icons.list, color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Meus Produtos',
                            style: TextStyle(
                              color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.black : Colors.grey, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onPressed: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? () => _navigateToMyProducts(context) : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        icon: Icon(Icons.shopping_bag, color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Vendas',
                            style: TextStyle(
                              color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.black : Colors.grey, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onPressed: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? () => _navigateToMyProducts(context) : null,
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
                        border: Border.all(color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        icon: Icon(Icons.analytics, color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.blue : Colors.grey),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Métricas',
                            style: TextStyle(
                              color: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? Colors.black : Colors.grey, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onPressed: (_isPaymentUpToDate && _hasPaymentData && _isAuthorized) ? () => _navigateToMyProducts(context) : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!(_isPaymentUpToDate && _hasPaymentData)) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Para utilizar as funcionalidades do sistema, é necessário realizar o pagamento do plano mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.red), 
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SubscriptionScreen(userId: razaoSocialCnpj, userEmail: email)),
                      );
                    },
                    icon: const Icon(
                      Icons.payment,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Realizar Pagamento',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => logout(context),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _navigateToMyProducts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyProductsScreen(username: widget.username)),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginForm()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _navigateToProductRegistration(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductRegistrationScreen(username: widget.username)),
    );
  }

  Future<void> _showSelectionDialog(BuildContext context) {
    return showDialog(
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      uploadProfileImage(imageFile);
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    setLoading(true);

    try {
      var distribuidorSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .where('email', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (distribuidorSnapshot.docs.isNotEmpty) {
        var distribuidorData = distribuidorSnapshot.docs.first.data();
        String razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';

        // Definindo o caminho da imagem no Firebase Storage
        String fileName = 'distribuidores/$razaoSocialCnpj/foto-perfil.jpg';
        await FirebaseStorage.instance.ref(fileName).putFile(imageFile);

        // Obtendo a URL da imagem
        String imageUrl = await FirebaseStorage.instance.ref(fileName).getDownloadURL();

        setState(() {
          _imageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil atualizada!")),
        );
      } else {
        throw 'Distribuidor não encontrado';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar foto de perfil: $e')),
      );
    }

    setLoading(false);
  }

  Future<void> removeSelfie() async {
    setLoading(true);

    try {
      var distribuidorSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .where('email', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (distribuidorSnapshot.docs.isNotEmpty) {
        var distribuidorData = distribuidorSnapshot.docs.first.data();
        String razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';

        // Definindo o caminho da imagem no Firebase Storage
        String fileName = 'distribuidores/$razaoSocialCnpj/foto-perfil.jpg';

        // Excluindo a imagem do Firebase Storage
        await FirebaseStorage.instance.ref(fileName).delete();

        setState(() {
          _imageUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil removida!")),
        );
      } else {
        throw 'Distribuidor não encontrado';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover foto de perfil: $e')),
      );
    }

    setLoading(false);
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }
}