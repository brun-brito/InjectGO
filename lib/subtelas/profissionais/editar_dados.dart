// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:inject_go/screens/login_screen.dart';
import 'package:inject_go/screens/profile_screen.dart';

class EditUserProfileScreen extends StatefulWidget {
  final String username;

  const EditUserProfileScreen({super.key, required this.username});

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

  Future<bool> updateEmail(String newEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String nome = _nameController.text;
    String sobrenome = _surnameController.text.split(' ')[0];
    try {
      await user?.verifyBeforeUpdateEmail(newEmail);
        
      var users = FirebaseFirestore.instance.collection('users');
      var querySnapshot = await users.where('email', isEqualTo: widget.username).get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'email': newEmail});
      }

      Map<String, dynamic> fullUserData = {'email-antigo': widget.username,'email-novo': newEmail};
      await firestore
        .collection('troca-email')
        .doc('$nome $sobrenome')
        .set(fullUserData);

      await showDialogEmail(newEmail);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: O usuário precisa se reautenticar (sair e entrar do perfil) antes de atualizar o email.")));
          return false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar o email: ${e.message} Tente novamente mais tarde.")));
          return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar o email: $e Tente novamente mais tarde.")));
        return false;
    }
  }


  Future<bool> alterarSenha(BuildContext context) async {
    String email = _emailController.text.trim(); 

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O e-mail não pode estar vazio.")),
      );
      return false;
    }

    try {
      var users = FirebaseFirestore.instance.collection('users');
      var querySnapshot = await users.where('email', isEqualTo: email).get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nenhum usuário encontrado com esse e-mail.")),
        );
        return false;
      }
      else{
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        for (var doc in querySnapshot.docs) {
          await doc.reference.update({'senha': 'SENHA-ALTERADA-EMAIL'});
        }
      }
      return true;
    
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar e-mail de redefinição de senha: ${e.message}")),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao processar a solicitação: ${e.toString()}")),
      );
      return false;
    }
  }

  Future<void> showDialogEmail(String email) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Atenção!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Você será direcionado(a) para a tela de Login, e deve realizar a verificação do seu novo e-mail no link enviado para caixa de $email (Verifique também se não está no lixo eletrônico/spam).",
                style: const TextStyle(fontSize: 17),  
              )
            ],
          ),
            actions: [
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginForm()),
                    (Route<dynamic> route) => false,
                  ); 
                },
              ),
            ],
        );
      },
    );
  }

  void _showForgotPasswordDialog() async{
    String value = _emailController.text;
    if(value.isEmpty || !value.contains('@') || !value.contains('.')){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha seu e-mail corretamente antes.")),
      );
    }else{
      if(await alterarSenha(context) == false){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao enviar e-mail de redefinição.")),
        );
      }
      else{
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Redefinir Senha"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Confira sua caixa de e-mail $value, para alterar sua senha, após isso, volte para realizar o login.",
                    style: const TextStyle(fontSize: 17),  
                  )
                ],
              ),
                actions: [
                  TextButton(
                    child: const Text('Ok'),
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
  }

Future<bool> _saveUserData() async {
  String emailOriginal = widget.username;
  String novoEmail = _emailController.text.trim();
  String telefone = _phoneController.text;
  String usuario = _usernameController.text;
  String bio = _bioController.text;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  var originalQuery = await firestore.collection('users').where('email', isEqualTo: emailOriginal).limit(1).get();
  if (originalQuery.docs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento original não encontrado.")));
    return false;
  }

  DocumentSnapshot originalDoc = originalQuery.docs.first;
  Map<String, dynamic>? originalData = originalDoc.data() as Map<String, dynamic>?;

  // Verificações de duplicidade
  if (novoEmail != originalData?['email']) {
    var mailQuery = await firestore.collection('users').where('email', isEqualTo: novoEmail).limit(1).get();
    if (mailQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cliente com este email já cadastrado.")));
      return false;
    }
  }
  if (usuario != originalData?['usuario']) {
    var usernameQuery = await firestore.collection('users').where('usuario', isEqualTo: usuario).limit(1).get();
    if (usernameQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cliente com este usuário já cadastrado.")));
      return false;
    }
  }
  if (telefone != originalData?['telefone']) {
    var telQuery = await firestore.collection('users').where('telefone', isEqualTo: telefone).limit(1).get();
    if (telQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cliente com este telefone já cadastrado.")));
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
    if (novoEmail != originalData?['email']) {
      if(await updateEmail(novoEmail)) {
        // Garantindo que a atualização de e-mail seja concluída
        updates['email'] = novoEmail;
      }
    }

    if (updates.isNotEmpty) {
      await originalDoc.reference.update(updates);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dados alterados com sucesso!")));
      Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (context) => ProfileScreen(username: _emailController.text)),
      (Route<dynamic> route) => false);
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
          title: const Text("Editar Perfil"),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(enabled:false, controller: _nameController, decoration: const InputDecoration(labelText: "Primeiro nome")),
              TextFormField(controller: _surnameController, decoration: const InputDecoration(labelText: "Sobrenome"),inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáÁÃãéÉíÍóÓÕõúÚâÂêÊîÎôÔûÛàÀèÈìÌòÒùÙçÇñÑ-\s]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isNotEmpty) {
                    final List<String> parts = newValue.text.split(' ');
                    final List<String> capitalizedParts = parts.map((part) {
                      if (part.isNotEmpty) {
                        return part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase();
                      }
                      return part;
                    }).toList();
                    final String result = capitalizedParts.join(' ');
                    return TextEditingValue(
                      text: result,
                      selection: TextSelection.collapsed(offset: result.length),
                    );
                  }
                  return newValue;
                }),
              ]),
              TextFormField(enabled:true, controller: _emailController, decoration: const InputDecoration(labelText: "E-mail")),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Telefone"),
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
              TextFormField(enabled:false, controller: _cpfController, decoration: const InputDecoration(labelText: "CPF")),
              TextFormField(enabled:false, controller: _councilNumberController, decoration: const InputDecoration(labelText: "Número do conselho")),
              TextFormField(enabled:false, controller: _councilStateController, decoration: const InputDecoration(labelText: "UF do conselho")),
              TextFormField(enabled:false, controller: _professionController, decoration: const InputDecoration(labelText: "Profissão")),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: "Biografia:", hintText: 'ex: Dentista, 30 anos, reside em Belo Horizonte'),
              inputFormatters: [LengthLimitingTextInputFormatter(80)]),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: "Nome de usuário"),
                inputFormatters: [
                  FilteringTextInputFormatter.singleLineFormatter, 
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\/\?\|\\_`~]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Você não pode editar um usuário vazio';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              TextButton(
              onPressed: 
                _showForgotPasswordDialog,
              child: const Text(
                "Trocar a senha",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
              ElevatedButton(
                style: 
                  ElevatedButton.styleFrom(
                    backgroundColor: /*const Color(0xFFf6cbc2),*/Colors.pink, 
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
                onPressed: () {
                  Navigator.pop(context);
                },
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
