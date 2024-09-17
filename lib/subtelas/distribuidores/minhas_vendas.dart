// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/formatadores/formata_data.dart';

class MinhasVendasScreen extends StatefulWidget {
  final String id;
  
  const MinhasVendasScreen({super.key, required this.id});
  
  @override
  _MinhasVendasScreenState createState() => _MinhasVendasScreenState();
}

class _MinhasVendasScreenState extends State<MinhasVendasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vendas'),
        centerTitle: true,
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
                  .where((doc) => !['solicitado', 'preparando', 'enviado'].contains(doc['status']))
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
            .snapshots()
        : FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(widget.id)
            .collection('vendas')
            .where('status', isEqualTo: status)
            .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Erro ao carregar vendas.'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Nenhuma venda encontrada.'));
      }

      final vendas = snapshot.data!.docs;

      return ListView.builder(  // Removi o Expanded aqui, pois não é necessário dentro de ListView
        itemCount: vendas.length,
        itemBuilder: (context, index) {
          final venda = vendas[index].data() as Map<String, dynamic>;
          final imageUrl = venda['productInfo']['imageUrl'] ?? ''; // Pega a URL da imagem do produto

          return Card(
            child: ListTile(
              leading: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported, size: 50), // Ícone padrão se não houver imagem
              title: Text(venda['productInfo']['nome'] ?? 'Produto sem nome'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preço: R\$ ${venda['productInfo']['preco']?.toStringAsFixed(2) ?? 'N/A'}'),
                  Text('Comprador: ${venda['buyerInfo']['nome'] ?? 'Desconhecido'}'),
                  Text('Data: ${formatDate(venda['data_pedido'])}'),
                  if (status == 'finalizado') Text('Status: ${venda['status']}'), // Mostra o motivo da finalização
                ],
              ),
              trailing: Text(venda['status']),
              onTap: () {
                _showVendaDetalhes(context, venda, vendas[index].id);
              },
            ),
          );
        },
      );
    },
  );
}

  // Exibir detalhes da venda e opções de aprovação ou rejeição
  void _showVendaDetalhes(BuildContext context, Map<String, dynamic> venda, String vendaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalhes do Pedido: ${venda['productInfo']['nome'] ?? 'Produto sem nome'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preço: R\$ ${venda['productInfo']['preco']?.toStringAsFixed(2) ?? 'N/A'}'),
              Text('Comprador: ${venda['buyerInfo']['nome'] ?? 'Desconhecido'}'),
              Text('Email: ${venda['buyerInfo']['email'] ?? 'Desconhecido'}'),
              Text('Telefone: ${venda['buyerInfo']['telefone'] ?? 'N/A'}'),
              const SizedBox(height: 20),
              Text('Status: ${venda['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            if (venda['status'] == 'solicitado') ...[
              TextButton(
                onPressed: () {
                  final String? buyerEmail = venda['buyerInfo']['email'];
                  final String? productId = venda['productInfo']['productId'];

                  if (buyerEmail != null && productId != null) {
                    _aprovarVenda(vendaId, buyerEmail, productId);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro: Informação do comprador ou produto está incompleta.')),
                    );
                  }
                },
                child: const Text('Aprovar', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  final String? buyerEmail = venda['buyerInfo']['email'];
                  final String? productId = venda['productInfo']['productId'];

                  if (buyerEmail != null && productId != null) {
                    _rejeitarVenda(vendaId, buyerEmail, productId);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro: Informação do comprador ou produto está incompleta.')),
                    );
                  }
                },
                child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        );
      },
    );
  }

  // Função para aprovar a venda e mudar o status para "preparando" para o distribuidor e o cliente
  void _aprovarVenda(String vendaId, String buyerEmail, String productId) async {
    try {
      // Atualizar o status da venda para 'preparando'
      await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(widget.id)  // ID do distribuidor
          .collection('vendas')
          .doc(vendaId)
          .update({
        'status': 'preparando',
      });

      // Obter o `compraId` a partir do documento da venda
      DocumentSnapshot vendaSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(widget.id)
          .collection('vendas')
          .doc(vendaId)
          .get();

      if (!vendaSnapshot.exists) {
        throw Exception('Venda não encontrada.');
      }

      // Converta os dados para um Map<String, dynamic>
      final Map<String, dynamic>? vendaData = vendaSnapshot.data() as Map<String, dynamic>?;

      if (vendaData == null || !vendaData.containsKey('compraId')) {
        throw Exception('compraId não encontrado na venda.');
      }

      final String compraId = vendaData['compraId'];

      // Atualizar o status da compra correspondente no Firestore (na coleção do comprador)
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: buyerEmail)
          .limit(1)
          .get()
          .then((querySnapshot) async {
        if (querySnapshot.docs.isNotEmpty) {
          String buyerId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(buyerId)
              .collection('compras')
              .doc(compraId)
              .update({
            'status': 'preparando',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda aprovada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar a venda: $e')),
      );
    }
  }

  void _rejeitarVenda(String vendaId, String buyerEmail, String productId) async {
    try {
      // Atualizar o status da venda para 'rejeitado'
      await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(widget.id)
          .collection('vendas')
          .doc(vendaId)
          .update({
        'status': 'rejeitado',
      });

      // Obter o `compraId` a partir do documento da venda
      DocumentSnapshot vendaSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(widget.id)
          .collection('vendas')
          .doc(vendaId)
          .get();

      final vendaData = vendaSnapshot.data() as Map<String, dynamic>?;

      if (vendaData == null || !vendaData.containsKey('compraId')) {
        throw Exception('compraId não encontrado na venda');
      }

      final String compraId = vendaData['compraId'];

      // Atualizar o status da compra correspondente no Firestore (na coleção do comprador)
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: buyerEmail)
          .limit(1)
          .get()
          .then((querySnapshot) async {
        if (querySnapshot.docs.isNotEmpty) {
          String buyerId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(buyerId)
              .collection('compras')
              .doc(compraId)
              .update({
            'status': 'rejeitado',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda rejeitada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar a venda: $e')),
      );
    }
  }

}
