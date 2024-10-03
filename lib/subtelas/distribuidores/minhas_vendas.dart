// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/formatadores/formata_data.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';
import 'package:inject_go/subtelas/distribuidores/vendas/detalhes_venda.dart';

class MinhasVendasScreen extends StatefulWidget {
  final String id;
  final String email;
  final int? initialTab;
  const MinhasVendasScreen({super.key, required this.id, required this.email,this.initialTab});
  
  @override
  _MinhasVendasScreenState createState() => _MinhasVendasScreenState();
}

class _MinhasVendasScreenState extends State<MinhasVendasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vendas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreenDistribuidor(username: widget.email),
              ),
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),  // Define a preferred size for the TabBar
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('distribuidores').doc(widget.id).collection('vendas').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return TabBar(
                  controller: _tabController,  // Adicionar o TabController aqui
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Solicitado (0)'),
                    Tab(text: 'Preparando (0)'),
                    Tab(text: 'Enviado (0)'),
                    Tab(text: 'Finalizado (0)'),
                  ],
                );
              }

              int solicitadoCount = snapshot.data!.docs.where((doc) => doc['status'] == 'solicitado').length;
              int preparandoCount = snapshot.data!.docs.where((doc) => doc['status'] == 'preparando').length;
              int enviadoCount = snapshot.data!.docs.where((doc) => doc['status'] == 'enviado').length;
              int finalizadoCount = snapshot.data!.docs
                  .where((doc) => doc['status'] == 'finalizado' || doc['status'] == 'rejeitado')
                  .length;

              return TabBar(
                controller: _tabController,  // Adicionar o TabController aqui
                isScrollable: true,
                indicatorColor: const Color.fromARGB(255, 236, 63, 121),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: [
                  Tab(text: 'Solicitado ($solicitadoCount)'),
                  Tab(text: 'Preparando ($preparandoCount)'),
                  Tab(text: 'Enviado ($enviadoCount)'),
                  Tab(text: 'Finalizado ($finalizadoCount)'),
                ],
              );
            },
          ),
        )
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVendasTab('solicitado'),
          _buildVendasTab('preparando'),
          _buildVendasTab('enviado'),
          _buildVendasTab('finalizado'),
        ],
      ),
    );
  }

Widget _buildVendasTab(String status) {
  return StreamBuilder<QuerySnapshot>(
    stream: (status == 'finalizado')
        ? FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(widget.id)
            .collection('vendas')
            .where('status', whereNotIn: ['solicitado', 'preparando', 'enviado'])
            .orderBy('data_criacao', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(widget.id)
            .collection('vendas')
            .where('status', isEqualTo: status)
            .orderBy('data_criacao', descending: true)
            .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Erro ao carregar vendas.'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Nenhuma venda encontrada.'));
      }

      final vendas = snapshot.data!.docs;

      // Agrupar as vendas por `payment_id`
      Map<String, List<QueryDocumentSnapshot>> groupedVendas = {};
      for (var venda in vendas) {
        String paymentId = venda['payment_id'];
        if (!groupedVendas.containsKey(paymentId)) {
          groupedVendas[paymentId] = [];
        }
        groupedVendas[paymentId]!.add(venda);
      }

      return ListView.builder(
        itemCount: groupedVendas.length,
        itemBuilder: (context, index) {
          final paymentId = groupedVendas.keys.elementAt(index);
          final vendasDoPedido = groupedVendas[paymentId]!;
          final primeiraVenda = vendasDoPedido.first.data() as Map<String, dynamic>;

          // Cálculo do total da compra (soma de todos os produtos no array 'produtos')
          double totalCompra = 0.0;
          for (var venda in vendasDoPedido) {
            List<dynamic> produtos = venda['produtos'];  // Acessa o array 'produtos'
            totalCompra += produtos.fold(0.0, (acc, produto) {
              return acc + (produto['productInfo']['preco'] ?? 0.0);
            });
          }

          return Card(
            child: ListTile(
              leading: (primeiraVenda['produtos'].isNotEmpty && primeiraVenda['produtos'][0]['productInfo']['imageUrl'] != null)
                  ? Image.network(
                      primeiraVenda['produtos'][0]['productInfo']['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported, size: 50),
              title: Text('Pedido: $paymentId'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total: R\$ ${totalCompra.toStringAsFixed(2)}'),
                  Text('Data: ${formatDate(primeiraVenda['data_criacao'])}'),
                ],
              ),
              onTap: () {
                // Navega para a página de detalhes das vendas agrupadas
                _showVendaDetalhes(context, vendasDoPedido, paymentId);
              },
            ),
          );
        },
      );
    },
  );
}

  // Exibir detalhes da venda e opções de aprovação ou rejeição
  void _showVendaDetalhes(BuildContext context, List<QueryDocumentSnapshot> vendasDoPedido, String paymentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesVendaScreen(
          vendasDoPedido: vendasDoPedido,
          paymentId: paymentId,
          distribuidorId: widget.id,
        ),
      ),
    );
  }

}
