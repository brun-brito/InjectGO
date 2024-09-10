// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MinhasComprasScreen extends StatefulWidget {
  final String userEmail;

  const MinhasComprasScreen({super.key, required this.userEmail});

  @override
  _MinhasComprasScreenState createState() => _MinhasComprasScreenState();
}

class _MinhasComprasScreenState extends State<MinhasComprasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Compras'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: fetchCompras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar compras: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma compra realizada.'));
          }

          final compras = snapshot.data!.docs;

          return ListView.builder(
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final compra = compras[index];
              final productName = compra['productName'];
              final price = compra['price'];
              final purchaseDate = (compra['purchaseDate'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd/MM/yyyy').format(purchaseDate);
              final paymentMethod = compra['paymentMethod'];
              
              return ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.green),
                title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Data: $formattedDate\nPagamento: $paymentMethod'),
                trailing: Text('R\$ ${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }

  Future<QuerySnapshot> fetchCompras() async {
    // Buscar as compras do usuário na coleção 'compras' associada ao email do profissional
    return await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userEmail)
        .limit(1)
        .get()
        .then((userSnapshot) {
      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;  // ID do documento do usuário

        return FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('compras')
            .orderBy('purchaseDate', descending: true)
            .get();
      } else {
        throw 'Usuário não encontrado.';
      }
    });
  }
}
