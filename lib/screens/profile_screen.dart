import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/main.dart';

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
              ],
          );
        },
      ),
    );
  }
  
   Widget buildUserInfo(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value ?? '-Não informado-'}", style: const TextStyle(fontSize: 20)),
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

}
