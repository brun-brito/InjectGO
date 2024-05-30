// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  // final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  bool _isButtonEnabled = false; 
  bool _isLoading = false; 
  bool _isObscure = true;
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
        title: const Text('Login'),
      ),
       
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment:
              Alignment.topCenter, 
              child: Image.asset(
                  'assets/images/logoInject.jpeg', //logo-distribuidora.jpeg',
                fit: BoxFit.fitWidth,
                width: 250,//300
                height: 150, 
              ),
            ),

            const Text(
              'Faça seu Login', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Digite seu e-mail:',
                  hintText: 'email-cadastrado@injectgo.com',),
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
              decoration: InputDecoration(
                labelText: 'Senha:',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              obscureText: _isObscure, 
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
                backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  await confirmaLogin();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Falha ao logar: ${e.toString()}")),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Entrar'),
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                "Esqueci a senha",
                style: TextStyle(
                  decoration: TextDecoration.underline, // Adiciona sublinhado ao texto
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
    return user['senha'] == password; 
  }
  
  Future<void> confirmaLogin() async {
    if (/*(await validateUser(_emailController.text, _passwordController.text)) &&*/ (await signInAuth(_emailController.text, _passwordController.text))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sucesso!"))
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(username: _emailController.text)),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-mail e/ou senha incorreto(s)"))
      );
    }
  }

  Future<bool> signInAuth(String email, String password) async {
    try {
      /*UserCredential userCredential = */await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,password: password,
      );
      // print("Usuário logado com sucesso: ${userCredential.user?.email}");
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // print('Nenhum usuário encontrado para esse email.');
      } else if (e.code == 'wrong-password') {
        // print('Senha incorreta fornecida para esse usuário.');
      } else {
        // print('Erro de login: ${e.message}');
      }
      return false;
    } catch (e) {
      // print('Erro: ${e.toString()}');
      return false;
    }
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

}

