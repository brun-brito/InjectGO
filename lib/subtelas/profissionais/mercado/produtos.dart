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
  String _selectedFilter = 'name_asc';
  String? _selectedBrand = 'Todos';
  List<String> _availableBrands = ['Todos'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    final querySnapshot = await FirebaseFirestore.instance.collectionGroup('produtos').get();
    final brands = querySnapshot.docs.map((doc) => doc['marca'] as String).toSet().toList();

    setState(() {
      _availableBrands = ['Todos', ...brands];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'name_asc',
                        child: Text('Nome (A-Z)'),
                      ),
                      DropdownMenuItem(
                        value: 'name_desc',
                        child: Text('Nome (Z-A)'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Preço (Menor-Maior)'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Preço (Maior-Menor)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedBrand,
                    isExpanded: true,
                    hint: const Text('Filtre por marca'),
                    items: _availableBrands.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrand = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar produtos. Por favor, tente novamente mais tarde.'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum produto disponível.'));
                }

                // Filtrar produtos com base no searchQuery e _selectedBrand
                var products = snapshot.data!.where((doc) {
                  final productName = doc['name'].toString().toLowerCase();
                  final productBrand = doc['marca'].toString().toLowerCase();

                  final matchesSearchQuery = productName.contains(searchQuery);
                  final matchesBrand = _selectedBrand == 'Todos' || productBrand == _selectedBrand!.toLowerCase();

                  return matchesSearchQuery && matchesBrand;
                }).toList();

                // Aplicar ordenação com base no _selectedFilter
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
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
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
                              productId: product['id'],
                              distributorPath: product.reference.parent.parent!.path,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                                child: Image.network(
                                  product['imageUrl'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
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
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> fetchProducts() async {
    // Passo 1: Buscar todos os distribuidores com pagamento em dia
    final distribuidoresSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .where('pagamento_em_dia', isEqualTo: true)
        .get();

    // Obter os IDs dos distribuidores com pagamento em dia
    final distribuidoresIds = distribuidoresSnapshot.docs.map((doc) => doc.id).toList();

    // Passo 2: Buscar todos os produtos que estão disponíveis (disponivel == true)
    final produtosSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('disponivel', isEqualTo: true)  // Filtro para pegar apenas produtos disponíveis
        .get();

    // Filtrar produtos que pertencem a distribuidores com pagamento em dia
    final produtosValidos = produtosSnapshot.docs.where((produtoDoc) {
      final parentDistribuidorId = produtoDoc.reference.parent.parent?.id;
      return distribuidoresIds.contains(parentDistribuidorId);
    }).toList();

    return produtosValidos;
  }
}
