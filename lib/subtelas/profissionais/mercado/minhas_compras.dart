// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:inject_go/screens/profile_screen.dart';

class MinhasComprasScreen extends StatefulWidget {
  final String userEmail;

  const MinhasComprasScreen({super.key, required this.userEmail});

  @override
  _MinhasComprasScreenState createState() => _MinhasComprasScreenState();
}

class _MinhasComprasScreenState extends State<MinhasComprasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 abas para os diferentes status de compras
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Compras'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.userEmail)),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color.fromARGB(255, 236, 63, 121),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),  
          unselectedLabelStyle: const TextStyle(fontSize: 12), 
          tabs: const [
            Tab(text: 'Aguardando distribuidor'),
            Tab(text: 'Preparando'),
            Tab(text: 'Enviado'),
            Tab(text: 'Finalizado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComprasTab('solicitado'),
          _buildComprasTab('preparando'),
          _buildComprasTab('enviado'),
          _buildComprasTab('finalizado'),
        ],
      ),
    );
  }

  Widget _buildComprasTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
          );
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Erro ao carregar compras ou usuário não encontrado.'));
        }

        final userId = userSnapshot.data!.docs.first.id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('compras')
              .where('status', isEqualTo: status)
              .orderBy('data_compra', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar compras.'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhuma compra encontrada.'));
            }

            final compras = snapshot.data!.docs;

            return ListView.builder(
              itemCount: compras.length,
              itemBuilder: (context, index) {
                final compra = compras[index];
                final productInfo = compra['productInfo'] as Map<String, dynamic>;
                final distributorInfo = compra['distributorInfo'] as Map<String, dynamic>;
                final dataCompra = (compra['data_compra'] as Timestamp).toDate();
                final formattedDate = DateFormat('dd/MM/yyyy').format(dataCompra);

                return Card(
                  child: ListTile(
                    leading: productInfo['imageUrl'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(productInfo['imageUrl']),
                            radius: 35,
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.shopping_bag),
                          ),
                    title: Text(productInfo['nome'] ?? 'Produto sem nome'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preço: R\$ ${productInfo['preco']?.toStringAsFixed(2) ?? 'N/A'}'),
                        Text('Distribuidor: ${distributorInfo['razao_social'] ?? 'Desconhecido'}'),
                        Text('Data: $formattedDate'),
                      ],
                    ),
                    trailing: Text(compra['status']),
                    onTap: () {
                      _showCompraDetalhes(context, compra.data() as Map<String, dynamic>, compras[index].id);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Exibir detalhes da compra
  void _showCompraDetalhes(BuildContext context, Map<String, dynamic> compra, String compraId) {
    final productInfo = compra['productInfo'] as Map<String, dynamic>;
    final distributorInfo = compra['distributorInfo'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalhes da Compra: ${productInfo['nome'] ?? 'Produto sem nome'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preço: R\$ ${productInfo['preco']?.toStringAsFixed(2) ?? 'N/A'}'),
              Text('Distribuidor: ${distributorInfo['razao_social'] ?? 'Desconhecido'}'),
              Text('CNPJ: ${distributorInfo['cnpj'] ?? 'N/A'}'),
              Text('Status: ${compra['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

}
