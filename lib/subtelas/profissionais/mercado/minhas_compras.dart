// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/subtelas/profissionais/mercado/pedidos/detalhes_pedidos.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: widget.userEmail)
                .limit(1)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Aguardando (0)'),
                    Tab(text: 'Preparando (0)'),
                    Tab(text: 'Enviado (0)'),
                    Tab(text: 'Finalizado (0)'),
                  ],
                );
              }

              final userId = userSnapshot.data!.docs.first.id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('compras')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Aguardando distribuidor (0)'),
                        Tab(text: 'Preparando (0)'),
                        Tab(text: 'Enviado (0)'),
                        Tab(text: 'Finalizado (0)'),
                      ],
                    );
                  }

                  // Contagem de compras por status
                  int aguardandoDistribuidor = snapshot.data!.docs
                      .where((doc) => doc['status'] == 'solicitado')
                      .length;
                  int preparando = snapshot.data!.docs
                      .where((doc) => doc['status'] == 'preparando')
                      .length;
                  int enviado = snapshot.data!.docs
                      .where((doc) => doc['status'] == 'enviado')
                      .length;
                  int finalizado = snapshot.data!.docs
                      .where((doc) =>
                          doc['status'] == 'finalizado' || doc['status'] == 'rejeitado')
                      .length;

                  return TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color.fromARGB(255, 236, 63, 121),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    tabs: [
                      Tab(text: 'Aguardando distribuidor ($aguardandoDistribuidor)'),
                      Tab(text: 'Preparando ($preparando)'),
                      Tab(text: 'Enviado ($enviado)'),
                      Tab(text: 'Finalizado ($finalizado)'),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComprasTab('solicitado'),
          _buildComprasTab('preparando'),
          _buildComprasTab('enviado'),
          _buildComprasTabFinalizado(),
        ],
      ),
    );
  }

  // Tab para exibir as compras agrupadas por status
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
              // .orderBy('data_compra', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
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
                final produtos = compra['produtos'] as List<dynamic>;
                final dataCompra = (compra['data_criacao'] as Timestamp).toDate();
                final formattedDate = DateFormat('dd/MM/yyyy').format(dataCompra);

                return Card(
                  child: ListTile(
                    title: Text('Pedido: ${compra.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data de pedido: $formattedDate'),
                        Text('Total de Itens: ${produtos.length}'),
                        ...produtos.map((produto) {
                          final productInfo = produto['productInfo'] as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Imagem do produto
                                  productInfo['imageUrl'] != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(productInfo['imageUrl']),
                                          radius: 30,
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.shopping_bag),
                                        ),
                                  const SizedBox(width: 8),

                                  // Use Expanded para o texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productInfo['nome'] ?? 'Produto sem nome',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                        Text(
                                          'Categoria: ${productInfo['categoria'] ?? 'Desconhecida'}',
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                        Text(
                                          'Preço: R\$ ${productInfo['preco']?.toStringAsFixed(2) ?? 'N/A'}',
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    trailing: Text(compra['status']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesCompraScreen(
                            comprasDoPedido: [compra],
                            paymentId: compra.id,
                            userEmail: widget.userEmail,
                          ),
                        ),
                      );
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

  // Tab para "finalizado" e "rejeitado"
  Widget _buildComprasTabFinalizado() {
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
              .where('status', whereIn: ['finalizado', 'rejeitado'])
              .orderBy('data_criacao', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
              );
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
                final produtos = compra['produtos'] as List<dynamic>;
                final dataCompra = (compra['data_criacao'] as Timestamp).toDate();
                final formattedDate = DateFormat('dd/MM/yyyy').format(dataCompra);

                return Card(
                  child: ListTile(
                    title: Text('Pedido: ${compra.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data de pedido: $formattedDate'),
                        Text('Total de Itens: ${produtos.length}'),
                        ...produtos.map((produto) {
                          final productInfo = produto['productInfo'] as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Imagem do produto
                                  productInfo['imageUrl'] != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(productInfo['imageUrl']),
                                          radius: 30,
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.shopping_bag),
                                        ),
                                  const SizedBox(width: 8),

                                  // Use Expanded para o texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productInfo['nome'] ?? 'Produto sem nome',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                        Text(
                                          'Categoria: ${productInfo['categoria'] ?? 'Desconhecida'}',
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                        Text(
                                          'Preço: R\$ ${productInfo['preco']?.toStringAsFixed(2) ?? 'N/A'}',
                                          overflow: TextOverflow.ellipsis, // Trunca o texto se for muito longo
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    trailing: Text(compra['status']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesCompraScreen(
                            comprasDoPedido: [compra],
                            paymentId: compra.id,
                            userEmail: widget.userEmail,
                          ),
                        ),
                      );
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

  String _translatePaymentStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      case 'refunded':
        return 'Reembolsado';
      default:
        return status;
    }
  }
}
