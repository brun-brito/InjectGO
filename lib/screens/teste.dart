// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Perfil do Usuário',
//       home: UserProfileScreen(username: 'user123'),  // Substitua 'user123' pelo identificador real do usuário
//     );
//   }
// }

// class UserProfileScreen extends StatefulWidget {
//   final String username;

//   UserProfileScreen({required this.username});

//   @override
//   _UserProfileScreenState createState() => _UserProfileScreenState();
// }

// class _UserProfileScreenState extends State<UserProfileScreen> {
//   bool isEditing = false;
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();

//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Perfil do Usuário"),
//         actions: [
//           if (!isEditing)
//             IconButton(
//               icon: Icon(Icons.edit),
//               onPressed: () {
//                 setState(() {
//                   isEditing = true;
//                 });
//               },
//             ),
//         ],
//       ),
//       body: isEditing ? buildEditForm() : buildProfileView(),
//     );
//   }

//   Widget buildProfileView() {
//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance.collection('users').doc(widget.username).get(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasError) {
//           return Center(child: Text("Erro ao carregar os dados."));
//         }
//         if (!snapshot.hasData || snapshot.data!.data() == null) {
//           return Center(child: Text("Nenhum dado encontrado para o usuário."));
//         }

//         var userData = snapshot.data!.data() as Map<String, dynamic>;
//         nameController.text = userData['nome'];
//         emailController.text = userData['email'];
//         return ListView(
//           padding: EdgeInsets.all(16),
//           children: <Widget>[
//             Text("Nome: ${userData['nome']}"),
//             Text("E-mail: ${userData['email']}"),
//             Text("Telefone: ${userData['telefone']}"),
//             // Adicione mais campos conforme necessário
//           ],
//         );
//       },
//     );
//   }

//   Widget buildEditForm() {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           TextField(
//             controller: nameController,
//             decoration: InputDecoration(labelText: 'Nome'),
//           ),
//           TextField(
//             controller: emailController,
//             decoration: InputDecoration(labelText: 'E-mail'),
//           ),
//           // Adicione mais campos conforme necessário
//           ElevatedButton(
//             onPressed: () => saveProfileData(),
//             child: Text("Salvar Alterações"),
//           ),
//         ],
//       ),
//     );
//   }

//   void saveProfileData() {
//     FirebaseFirestore.instance.collection('users').doc(widget.username)
//       .update({
//         'nome': nameController.text,
//         'email': emailController.text,
//         // Adicione mais campos conforme necessário
//       }).then((_) {
//         print("Dados atualizados com sucesso!");
//         setState(() {
//           isEditing = false;
//         });
//       }).catchError((error) {
//         print("Erro ao atualizar os dados: $error");
//       });
//   }
// }
