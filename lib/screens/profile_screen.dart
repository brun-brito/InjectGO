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

  UserProfileScreen({required this.username});

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
            padding: EdgeInsets.all(16),
            children: <Widget>[
              Text("Nome: $fullName", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("E-mail: ${userData['email'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Telefone: ${userData['telefone'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("CPF: ${userData['cpf'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Número conselho: ${userData['conselho'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("UF Conselho: ${userData['estadoConselho'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Profissão: ${userData['profissao'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Nome de usuário: ${userData['usuario'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Foto: ${userData['caminhoFoto'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Data de nascimento: ${userData['dataNasc'] ?? '-Não informado-'}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
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
