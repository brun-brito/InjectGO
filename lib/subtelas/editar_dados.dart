import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:inject_go/screens/profile_screen.dart';

class EditUserProfileScreen extends StatefulWidget {
  final String username;

  const EditUserProfileScreen({Key? key, required this.username}) : super(key: key);

  @override
  _EditUserProfileScreenState createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cpfController;
  late TextEditingController _councilNumberController;
  late TextEditingController _councilStateController;
  late TextEditingController _professionController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cpfController = TextEditingController();
    _councilNumberController = TextEditingController();
    _councilStateController = TextEditingController();
    _professionController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var userQuery = await firestore.collection('users').where('email', isEqualTo: widget.username).limit(1).get();
    if (userQuery.docs.isNotEmpty) {
      var userData = userQuery.docs.first.data();
      _nameController.text = userData['nome'];
      _surnameController.text = userData['sobrenome'];
      _emailController.text = userData['email'];
      _phoneController.text = userData['telefone'];
      _cpfController.text = userData['cpf'];
      _councilNumberController.text = userData['conselho'];
      _councilStateController.text = userData['estadoConselho'];
      _professionController.text = userData['profissao'];
      _usernameController.text = userData['usuario'];
      _bioController.text = userData['bio'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _councilNumberController.dispose();
    _councilStateController.dispose();
    _professionController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }


  Future<bool> _saveUserData() async {
    String email = _emailController.text.trim();
    String telefone = _phoneController.text;
    String usuario = _usernameController.text;
    String bio = _bioController.text;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot? originalDoc;

    var originalQuery = await firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (originalQuery.docs.isNotEmpty) {
      originalDoc = originalQuery.docs.first;
    }

    // Verifica se existe e faz cast dos dados para Map<String, dynamic>
    Map<String, dynamic>? originalData = originalDoc?.data() as Map<String, dynamic>?;

    if (usuario != originalData?['usuario']) {
      var usernameQuery = await firestore.collection('users').where('usuario', isEqualTo: usuario).limit(1).get();
      if (usernameQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cliente com este usuário já cadastrado.")));
        return false;
      }
    }
    if (telefone != originalData?['telefone']) {
      var telQuery = await firestore.collection('users').where('telefone', isEqualTo: telefone).limit(1).get();
      if (telQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cliente com este telefone já cadastrado.")));
        return false;
      }
    }

    try {
      Map<String, dynamic> updates = {};
      if (_surnameController.text != originalData?['sobrenome']) {
        updates['sobrenome'] = _surnameController.text;
      }
      if (telefone != originalData?['telefone']) {
        updates['telefone'] = telefone;
      }
      if (usuario != originalData?['usuario']) {
        updates['usuario'] = usuario;
      }
      if (bio != originalData?['bio']) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        await originalDoc?.reference.update(updates);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dados alterados com sucesso!")));
        Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => ProfileScreen(username: _emailController.text)),
        (Route<dynamic> route) => false,
      );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma alteração detectada.")));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao alterar dados: ${e.toString()}")));
      return false;
    }
  }



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Editar Perfil"),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(enabled:false, controller: _nameController, decoration: InputDecoration(labelText: "Primeiro nome")),
              TextFormField(controller: _surnameController, decoration: InputDecoration(labelText: "Sobrenome")),
              TextFormField(enabled:false, controller: _emailController, decoration: InputDecoration(labelText: "E-mail")),
              TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: "Telefone"),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11),],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Você não pode editar um telefone vazio';
                    }
                    else if (value.length != 11) {
                      return 'Por favor, preencha um telefone válido';
                    }
                    return null;
                  },
              ),
              TextFormField(enabled:false, controller: _cpfController, decoration: InputDecoration(labelText: "CPF")),
              TextFormField(enabled:false, controller: _councilNumberController, decoration: InputDecoration(labelText: "Número do conselho")),
              TextFormField(enabled:false, controller: _councilStateController, decoration: InputDecoration(labelText: "UF do conselho")),
              TextFormField(enabled:false, controller: _professionController, decoration: InputDecoration(labelText: "Profissão")),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: "Biografia:",
                hintText: 'ex: Dentista, 30 anos, reside em Belo Horizonte')),
              TextFormField(controller: _usernameController, decoration: InputDecoration(labelText: "Nome de usuário"),
                inputFormatters: [
                  FilteringTextInputFormatter.singleLineFormatter, 
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\/\?\|\\_`~]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Você não pode editar um usuário vazio';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              ElevatedButton(
                style: 
                  ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink, 
                    foregroundColor: Colors.white,
                  ),
                onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true); 
                try {
                  await _saveUserData();  
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Falha: ${e.toString()}"))
                    );
                } finally {
                  setState(() => _isLoading = false);  
                }
              },           
                child: _isLoading 
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                  )
                : const Text('Salvar Alterações'),
            ),
            Center(
            child: TextButton(
                onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
