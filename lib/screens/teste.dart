import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/main.dart';
import 'package:inject_go/screens/login_screen.dart';
import 'package:inject_go/screens/token.dart';
import 'package:inject_go/screens/editar_dados.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfil do Usuário',
      home: Home(),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String username;

  UserProfileScreen({required this.username});  // herda o email digitado na tela de login pra poder puxar do banco

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil do Usuário"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(username),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar os dados."));
          }
          if (snapshot.data == null) {
            return Center(child: Text("Nenhum dado encontrado para o usuário."));
          }

          var userData = snapshot.data!;
          String fullName = "${userData['nome']} ${userData['sobrenome']}";
          return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                buildUserInfo("Nome Completo", fullName),
                buildUserInfo("E-mail", userData['email']),
                buildUserInfo("Telefone", userData['telefone']),
                buildUserInfo("CPF", userData['cpf']),
                buildUserInfo("Número conselho", userData['conselho']),
                buildUserInfo("UF Conselho", userData['estadoConselho']),
                buildUserInfo("Profissão", userData['profissao']),
                buildUserInfo("Nome de usuário", userData['usuario']),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TOTPDisplay())
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Gerar Token para compra"),
                ),
                
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Sair"),
                ),
              ],
            );
          },
        ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditUserProfileScreen(username: username)),
        ),
        child: Icon(Icons.edit),
        backgroundColor: Colors.blue,
        ),
    );
  }

    
Widget buildUserInfo(String label, String? value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20, color: Colors.black), 
          children: <TextSpan>[
            TextSpan(
              text: "$label: ", 
              style: const TextStyle(fontWeight: FontWeight.bold), 
            ),
            TextSpan(
              text: value ?? '-Não informado-', 
              style: const TextStyle(fontWeight: FontWeight.normal), 
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}


Future<Map<String, dynamic>?> getUserData(String usuario) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  try {
    var userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: usuario)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return null;  // Nenhum usuário encontrado.
    }

    return userQuery.docs.first.data();  // Retorna todos os dados do usuário.
  } catch (e) {
    print('Erro ao buscar dados do usuário: $e');
    return null;
  }
}

Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginForm()),
    (Route<dynamic> route) => false,
  );
}

void editarDados() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Um usuário está logado
    print("Usuário logado: ${user.email}");
  } else {
    // Nenhum usuário está logado
    print("Nenhum usuário está logado.");
  }
}

}
