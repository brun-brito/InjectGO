// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/subtelas/profissionais/mercado/detalhes_produtos.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String searchQuery = '';
  String _selectedFilter = 'name_asc'; // Variável de estado para o filtro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Padding(
  padding: const EdgeInsets.all(8.0),
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Buscar produto...',
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Ajusta a altura
    ),
    onChanged: (value) {
      setState(() {
        searchQuery = value.toLowerCase(); // Atualiza a pesquisa
      });
    },
  ),
),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'name_asc',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined),
                      SizedBox(width: 8),
                      Text('Nome (A-Z)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'name_desc',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined),
                      SizedBox(width: 8),
                      Text('Nome (Z-A)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'price_asc',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined),
                      SizedBox(width: 8),
                      Text('Preço (Menor-Maior)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'price_desc',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined),
                      SizedBox(width: 8),
                      Text('Preço (Maior-Menor)'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar produtos: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto disponível.'));
                }

                final products = snapshot.data!.docs.where((doc) {
                  final productName = doc['name'].toString().toLowerCase();
                  return productName.contains(searchQuery);
                }).toList();

                // Aplicando o filtro de ordenação
                products.sort((a, b) {
                  switch (_selectedFilter) {
                    case 'name_asc':
                      return a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase());
                    case 'name_desc':
                      return b['name'].toString().toLowerCase().compareTo(a['name'].toString().toLowerCase());
                    case 'price_asc':
                      return (a['price'] as num).compareTo(b['price'] as num);
                    case 'price_desc':
                      return (b['price'] as num).compareTo(a['price'] as num);
                    default:
                      return 0;
                  }
                });

                if (products.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // número de cards por linha
                    childAspectRatio: 0.8, // proporção dos cards
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: product['id'], // Passando o ID do produto
                              distributorPath: product.reference.parent.parent!.path, // Passando o caminho do distribuidor
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Image.network(
                                  product['imageUrl'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R\$ ${product['price'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[600], // Ajuste a cor da setinha se necessário
                                    size: 16, // Tamanho da setinha
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> fetchProducts() {
    return FirebaseFirestore.instance
        .collectionGroup('produtos') 
        .get();
  }
}
