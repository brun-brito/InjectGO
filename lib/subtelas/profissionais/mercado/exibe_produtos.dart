// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/subtelas/profissionais/mercado/carrinho.dart';
// import 'package:inject_go/subtelas/profissionais/mercado/detalhes_produtos.dart';

class ProdutosDistribuidores extends StatefulWidget {
  final String distribuidorId;
  final String distribuidorNome;
  final String emailProfissional;
  final Position posicao;

  const ProdutosDistribuidores({
    super.key,
    required this.distribuidorId,
    required this.distribuidorNome,
    required this.emailProfissional, 
    required this.posicao,
  });

  @override
  _ProdutosDistribuidoresState createState() => _ProdutosDistribuidoresState();
}

class _ProdutosDistribuidoresState extends State<ProdutosDistribuidores> {
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
    // Buscar produtos do distribuidor atual
    final produtosSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(widget.distribuidorId)
        .collection('produtos')
        .where('disponivel', isEqualTo: true)
        .where('quantidade_disponivel', isGreaterThan: 0)
        .get();

    final brands = produtosSnapshot.docs
        .map((doc) => doc['marca'].toString().toLowerCase().trim())
        .toSet()
        .toList();

    final categories = produtosSnapshot.docs
        .map((doc) => doc['categoria'].toString().toLowerCase().trim())
        .toSet()
        .toList();

    setState(() {
      _availableBrands = ['Todos', ...brands];
      _availableCategories = ['Todas', ...categories];
    });
  }

@override
Widget build(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  const double itemWidth = 150.0;
  final int crossAxisCount = screenWidth ~/ itemWidth;

  return Scaffold(
    appBar: AppBar(
      title: Text(widget.distribuidorNome),
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
                    builder: (context) => CarrinhoScreen(
                      cartProducts: _cartProducts,
                      email: widget.emailProfissional,
                      posicao: widget.posicao,
                    ),
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
    body: ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // Campo de busca
        TextField(
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 10),
        // Filtro de visibilidade
        Row(
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
                    _filtersVisible
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_off_sharp,
                    color: _filtersVisible ? Colors.grey[800] : Colors.red,
                    size: 28.0,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Filtrar',
                    style: TextStyle(
                      color: _filtersVisible ? Colors.grey[800] : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Seção de filtros visível
        if (_filtersVisible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filtrar por Marca:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.grey),
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.grey),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Ordenar por:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedFilter,
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
                  ],
                ),
              ],
            ),
          ),
        // Lista de produtos
        FutureBuilder<List<QueryDocumentSnapshot>>(
          future: fetchProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 236, 63, 121)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum produto disponível.'));
            }

            // Filtragem e ordenação dos produtos
            var products = snapshot.data!.where((doc) {
              final productName = doc['name'].toString().toLowerCase();
              final productBrand = doc['marca'].toString().toLowerCase();
              final productCategory = doc['categoria'].toString().toLowerCase();

              final matchesSearchQuery = productName.contains(searchQuery);
              final matchesBrand = _selectedBrand == 'Todos' ||
                  productBrand == _selectedBrand.toLowerCase();
              final matchesCategory = _selectedCategory == 'Todas' ||
                  productCategory == _selectedCategory.toLowerCase();

              return matchesSearchQuery && matchesBrand && matchesCategory;
            }).toList();

            // Ordenação com base no filtro selecionado
            products.sort((a, b) {
              switch (_selectedFilter) {
                case 'name_asc':
                  return a['name']
                      .toString()
                      .toLowerCase()
                      .compareTo(b['name'].toString().toLowerCase());
                case 'name_desc':
                  return b['name']
                      .toString()
                      .toLowerCase()
                      .compareTo(a['name'].toString().toLowerCase());
                case 'price_asc':
                  return (a['price'] as num).compareTo(b['price'] as num);
                case 'price_desc':
                  return (b['price'] as num).compareTo(a['price'] as num);
                default:
                  return 0;
              }
            });

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
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
                    // TODO: Lógica para navegar para a página de detalhes do produto
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
                                      isInCart
                                          ? '`${product['name']}` removido do carrinho!'
                                          : '`${product['name']}` adicionado ao carrinho!',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                },
                                icon: Icon(
                                  isInCart
                                      ? Icons.remove_shopping_cart
                                      : Icons.add_shopping_cart,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isInCart ? 'Remover' : 'Adicionar ao carrinho',
                                  style: const TextStyle(color: Colors.white),
                                ),
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
      ],
    ),
  );
}


  Future<List<QueryDocumentSnapshot>> fetchProducts() async {
    // Busca os produtos do distribuidor específico (com base no distribuidorId)
    final produtosSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(widget.distribuidorId)
        .collection('produtos')
        .where('disponivel', isEqualTo: true)
        .where('quantidade_disponivel', isGreaterThanOrEqualTo: 0)
        .get();

    return produtosSnapshot.docs;
  }
}
