// ignore_for_file: library_private_types_in_public_api
import 'package:inject_go/screens/welcome_screen.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  bool _isButtonEnabled = false; 
  FirebaseFirestore firestore = FirebaseFirestore.instance;

    @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty && _emailController.text.contains('@') && _emailController.text.contains('.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), //seta pra voltar
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
        ),
        title: const Text('Faça seu Login'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Digite seu e-mail:'),
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter, 
              ],
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) {
                  return 'Por favor, preencha seu e-mail corretamente';
                }

                return null;
              },
            ),

            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha:'),
              obscureText: true, // Esconde a senha
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha sua senha';
                }
                return null;
              },
            ),

              
            const SizedBox(height: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  confirmaLogin();  
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Falha ao logar: ${e.toString()}"))
                  );
                }
              },
              child: Text('Entrar'),
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                "Esqueci a senha",
                style: TextStyle(
                  decoration: TextDecoration.underline,  // Adiciona sublinhado ao texto
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> validateUser(String username, String password) async {
    final querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: username)
      .limit(1)
      .get();

    if (querySnapshot.docs.isEmpty) {
      return false;
    }

    final user = querySnapshot.docs.first;
    return user['senha'] == password; // Compare a senha do banco de dados com a fornecida
  }
  
  void confirmaLogin() async {
    if (await validateUser(_emailController.text, _passwordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sucesso!"))
        );
        
        // Navega para a tela de perfil passando o usuário como argumento
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(username: _emailController.text),
          ),
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário ou senha incorreta"))
      );
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _newPasswordController = TextEditingController();
        final _confirmPasswordController = TextEditingController();
        return AlertDialog(
          title: const Text("Redefinir Senha"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail Cadastrado:',
                ),
              ),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nova Senha:',
                ),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nova Senha:',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Salvar'),
              onPressed: () {
                if(_emailController.text.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preencha o seu e-mail")),
                  );}
                else if(_newPasswordController.text.isEmpty || _newPasswordController.text.length < 6){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("A senha deve ter no mínimo 6 caracteres")),
                  );}
                else if (_newPasswordController.text == _confirmPasswordController.text) {
                  alterarSenha(_emailController.text, _newPasswordController.text);
                  Future.delayed(Duration(seconds: 1), () {
                    Navigator.of(context).pop(); // Fechar o diálogo após a atualização
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("As senhas não coincidem!")),
                  );
                }
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {Navigator.of(context).pop();} 
            ),
          ],
        );
      },
    );
  }

  Future<void> alterarSenha(String email, String newPassword) async {
    var querySnapshot = await firestore
      .collection('users')
      .where('email', isEqualTo: email)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Se o documento existe, atualiza a senha
      String docId = querySnapshot.docs.first.id;
      await firestore
        .collection('users')
        .doc(docId)
        .update({'senha': newPassword});        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Senha atualizada com sucesso!")),
      );
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar senha")),
      );
    }
  }

}

