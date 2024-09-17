// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/subtelas/profissionais/mercado/carrinho.dart';
import 'package:inject_go/formatadores/formata_string.dart';

class MarketplaceScreen extends StatefulWidget {
  final String email;

  const MarketplaceScreen({super.key, required this.email});

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String searchQuery = '';
  String _selectedFilter = 'name_asc';
  String _selectedBrand = 'Todos';
  String _selectedCategory = 'Todas';
  List<String> _availableBrands = ['Todos'];
  List<String> _availableCategories = ['Todas'];
  final TextEditingController _searchController = TextEditingController();
  final List<DocumentSnapshot> _cartProducts = [];
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    fetchFilters();
  }

  Future<void> fetchFilters() async {
    // Passo 1: Buscar todos os distribuidores com pagamento em dia
    final distribuidoresSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .where('pagamento_em_dia', isEqualTo: true)
        .get();

    // Obter os IDs dos distribuidores com pagamento em dia
    final distribuidoresIds = distribuidoresSnapshot.docs.map((doc) => doc.id).toList();

    // Passo 2: Buscar todos os produtos disponíveis (disponivel == true) que pertencem a esses distribuidores
    final produtosSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('disponivel', isEqualTo: true)
        .get();

    // Filtrar produtos que pertencem a distribuidores com pagamento em dia
    final produtosValidos = produtosSnapshot.docs.where((produtoDoc) {
      final parentDistribuidorId = produtoDoc.reference.parent.parent?.id;
      return distribuidoresIds.contains(parentDistribuidorId);
    }).toList();

    final brands = produtosValidos
        .map((doc) => primeiraMaiuscula(doc['marca'].toString().toLowerCase().trim()))
        .toSet()
        .toList();

    final categories = produtosValidos
        .map((doc) => primeiraMaiuscula(doc['categoria'].toString().toLowerCase().trim()))
        .toSet()
        .toList();

    setState(() {
      _availableBrands = ['Todos', ...brands];
      _availableCategories = ['Todas', ...categories];
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                iconSize: 30,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarrinhoScreen(cartProducts: _cartProducts, email: widget.email),
                    ),
                  );
                },
              ),
              if (_cartProducts.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 8,    
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartProducts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _filtersVisible = !_filtersVisible;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _filtersVisible ? Icons.filter_alt_rounded : Icons.filter_alt_off_sharp,
                        color: Colors.grey[800],
                        size: 28.0,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Filtrar',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: _filtersVisible, // Controla a visibilidade dos filtros
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtrar por Marca:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            DropdownButton<String>(
                              value: _selectedBrand,
                              isExpanded: true,
                              items: _availableBrands.map((brand) {
                                return DropdownMenuItem<String>(
                                  value: brand,
                                  child: Text(brand),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBrand = value!;
                                });
                              },
                              underline: Container(
                                height: 1,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtrar por Categoria:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _availableCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                              underline: Container(
                                height: 1,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Ordenação (mantida como antes)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ordenar por:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      DropdownButton<String>(
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
                        underline: Container(
                          height: 1,
                          color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
          // Lista de produtos com a opção de adicionar ao carrinho
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum produto disponível.'));
                }

                // Filtrar produtos com base no searchQuery, _selectedBrand e _selectedCategory
                var products = snapshot.data!.where((doc) {
                  final productName = doc['name'].toString().toLowerCase();
                  final productBrand = doc['marca'].toString().toLowerCase();
                  final productCategory = doc['categoria'].toString().toLowerCase();

                  final matchesSearchQuery = productName.contains(searchQuery);
                  final matchesBrand = _selectedBrand == 'Todos' || productBrand == _selectedBrand.toLowerCase();
                  final matchesCategory = _selectedCategory == 'Todas' || productCategory == _selectedCategory.toLowerCase();

                  return matchesSearchQuery && matchesBrand && matchesCategory;
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
                    bool isInCart = _cartProducts.any((p) => p.id == product.id);
                    return GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ProductDetailScreen(
                        //       productId: product['id'],
                        //       distributorPath: product.reference.parent.parent!.path,
                        //       email: widget.email,
                        //     ),
                        //   ),
                        // );
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
                                  const SizedBox(height: 4),
                                  // Adicionando o botão de "Adicionar ao Carrinho"
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        if (isInCart) {
                                          _cartProducts.removeWhere((p) => p.id == product.id);
                                        } else {
                                          _cartProducts.add(product);
                                        }
                                      });
                                      final snackBar = SnackBar(
                                        content: Text(
                                          isInCart ? '`${product.get('name')}` removido do carrinho!' : '`${product.get('name')}` adicionado ao carrinho!',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                    },
                                    icon: Icon(
                                      isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                                      color: Colors.white,
                                    ),
                                    label: Text(isInCart ? 'Remover' : 'Adicionar ao\n carrinho', style: const TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInCart ? Colors.red : Colors.green,
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
    final distribuidoresSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .where('pagamento_em_dia', isEqualTo: true)
        .get();

    final distribuidoresIds = distribuidoresSnapshot.docs.map((doc) => doc.id).toList();

    final produtosSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('disponivel', isEqualTo: true)
        .get();

    final produtosValidos = produtosSnapshot.docs.where((produtoDoc) {
      final parentDistribuidorId = produtoDoc.reference.parent.parent?.id;
      return distribuidoresIds.contains(parentDistribuidorId);
    }).toList();

    return produtosValidos;
  }
}