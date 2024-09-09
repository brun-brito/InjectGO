// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/mercado_pago/comprar_produto.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String distributorPath;

  const ProductDetailScreen({super.key, required this.productId, required this.distributorPath});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? razaoSocial;
  String? cnpj;
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    extractRazaoSocialAndCnpj();
  }

  void extractRazaoSocialAndCnpj() {
    String razaoCnpj = widget.distributorPath.split('/')[1];
    List<String> razaoCnpjParts = razaoCnpj.split(' - ');

    if (razaoCnpjParts.length == 2) {
      razaoSocial = razaoCnpjParts[0];
      cnpj = razaoCnpjParts[1];
    } else {
      razaoSocial = 'Razão social desconhecida';
      cnpj = 'CNPJ desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: fetchProductDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar detalhes do produto: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Produto não encontrado.'));
          }

          var product = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              product['imageUrl'],
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nome: ${product['name']}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Preço: R\$ ${product['price'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Marca: ${product['marca']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Descrição: ${product['description']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Distribuidor: $razaoSocial',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CNPJ: $cnpj',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPurchaseScreen(initPoint: product['produto_mp']['init_point']),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Comprar Produto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: const Center(
                  child: Text(
                    '© InjectGO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<DocumentSnapshot> fetchProductDetails() async {
    return firebase
        .doc('${widget.distributorPath}/produtos/${widget.productId}')
        .get();
  }
}
