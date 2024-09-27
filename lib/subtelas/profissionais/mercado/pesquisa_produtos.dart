// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/subtelas/profissionais/mercado/carrinho.dart';

class PesquisaProdutosScreen extends StatefulWidget {
  final Position posicao;
  final String emailProfissional;
  final String? categoriaFiltrada;

  const PesquisaProdutosScreen({
    super.key,
    required this.posicao,
    required this.emailProfissional,
    this.categoriaFiltrada, // Nova categoria para filtro
  });

  @override
  _PesquisaProdutosScreenState createState() => _PesquisaProdutosScreenState();
}

class _PesquisaProdutosScreenState extends State<PesquisaProdutosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<DocumentSnapshot> _allProducts = [];
  final List<DocumentSnapshot> _cartProducts = [];
  String? _currentCartDistributorId;
  String? _currentCartDistributorName;
  bool _isLoading = false;
  bool _canAdd = false;

  @override
  void initState() {
    super.initState();
    fetchAllProducts();
  }

  Future<void> fetchAllProducts() async {
    setState(() {
      _isLoading = true;
    });
    // Busca todos os distribuidores com pagamento em dia
    final distribuidoresSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .where('pagamento_em_dia', isEqualTo: true)
        .get();

    // IDs dos distribuidores com pagamento em dia
    final distribuidoresIds = distribuidoresSnapshot.docs.map((doc) => doc.id).toList();

    // Busca todos os produtos disponíveis pertencentes a esses distribuidores
    final produtosSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('disponivel', isEqualTo: true)
        .where('quantidade_disponivel', isGreaterThan: 0)
        .get();

    // Filtra produtos que pertencem a distribuidores com pagamento em dia
    final produtosValidos = produtosSnapshot.docs.where((produtoDoc) {
      final parentDistribuidorId = produtoDoc.reference.parent.parent?.id;
      return distribuidoresIds.contains(parentDistribuidorId);
    }).toList();

     // Se a categoria for passada, aplica o filtro de categoria
    if (widget.categoriaFiltrada != null && widget.categoriaFiltrada!.isNotEmpty) {
      final produtosFiltradosPorCategoria = produtosValidos.where((produto) {
        final categoriaProduto = removeAcento(produto['categoria'].toString().toLowerCase());

        // Aplica o filtro "contains" para verificar se a categoria contém a palavra-chave, sem acentos
        return categoriaProduto.contains(removeAcento(widget.categoriaFiltrada!.toLowerCase()));
      }).toList();

      setState(() {
        _allProducts = produtosFiltradosPorCategoria;
        _isLoading = false;
      });
    } else {
      setState(() {
        _allProducts = produtosValidos;
        _isLoading = false;
      });
    }
  }

  Future<String> _getDistributorName(String distributorId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distributorId)
        .get();

    return docSnapshot['razao_social'] as String;
  }

  void _addToCart(DocumentSnapshot product, String distributorId, String distributorName) {
    // Se o carrinho estiver vazio ou o produto for do mesmo distribuidor, adiciona ao carrinho
    if (_currentCartDistributorId == null || _currentCartDistributorId == distributorId) {
      setState(() {
        _canAdd = true;
        _cartProducts.add(product);
        _currentCartDistributorId = distributorId; // Define o distribuidor atual do carrinho
        _currentCartDistributorName = distributorName; // Define o nome do distribuidor atual do carrinho
      });
    } else {
      setState(() {
        _canAdd = false;
      });
      _showDistributorConflictDialog(product, distributorId, distributorName);
    }
  }

  void _removeFromCart(DocumentSnapshot product) {
    setState(() {
      _canAdd = true;
      _cartProducts.removeWhere((p) => p.id == product.id);

      // Se o carrinho estiver vazio, reseta o distribuidor atual
      if (_cartProducts.isEmpty) {
        _currentCartDistributorId = null;
        _currentCartDistributorName = null;
      }
    });
  }

  void _showDistributorConflictDialog(DocumentSnapshot product, String distributorId, String distributorName) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30), // Ícone de atenção
              SizedBox(width: 10),
              Text(
                'Produto de outra loja!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            "Você já possui produtos da loja '$_currentCartDistributorName' no carrinho. Deseja esvaziar o carrinho para adicionar este produto?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700], // Cor do texto do botão "Cancelar"
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red, // Cor do botão "Esvaziar Carrinho"
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Esvaziar Carrinho'),
              onPressed: () {
                setState(() {
                  _cartProducts.clear(); // Esvazia o carrinho
                  _currentCartDistributorId = null; // Remove o distribuidor atual do carrinho
                  _currentCartDistributorName = null; // Remove o nome do distribuidor atual
                  _addToCart(product, distributorId, distributorName); // Adiciona o novo produto ao carrinho
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisa de Produtos'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.emailProfissional)),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Ícone do carrinho com contador
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
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 236, 63, 121),
                      shape: BoxShape.circle,
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
          if (_currentCartDistributorName != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Comprando na loja: $_currentCartDistributorName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
                  )
                : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double itemWidth = 150.0;
    final int crossAxisCount = screenWidth ~/ itemWidth;

    final filteredProducts = _allProducts.where((product) {
        final productName = product['name'].toString().toLowerCase();
        return productName.contains(searchQuery);
      }).toList();

      // Ordena os produtos por nome em ordem alfabética
      filteredProducts.sort((a, b) {
        return a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase());
      });

      if (filteredProducts.isEmpty) {
        return const Center(
          child: Text('Nenhum produto encontrado.'),
        );
      }

    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        var product = filteredProducts[index];
        bool isInCart = _cartProducts.any((p) => p.id == product.id);
        String distributorId = product.reference.parent.parent?.id ?? '';

        return FutureBuilder<String>(
          future: _getDistributorName(distributorId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
            }
            String distributorName = snapshot.data ?? 'Distribuidor Desconhecido';

            return GestureDetector(
              onTap: () {
                // detalhes do produto
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
                          Text(
                            'Loja: $distributorName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isInCart) {
                                _removeFromCart(product); // Função para remover produto do carrinho
                                final snackBar = SnackBar(
                                  content: Text(
                                    "'${product['name']}' removido do carrinho!",
                                  ),
                                  duration: const Duration(seconds: 1),
                                );
                                if(_canAdd) {
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                }
                              } else {
                                _addToCart(product, distributorId, distributorName); // Função para adicionar produto ao carrinho
                                final snackBar = SnackBar(
                                  content: Text(
                                    "'${product['name']}' adicionado ao carrinho!",
                                  ),
                                  duration: const Duration(seconds: 1),
                                );
                                if(_canAdd) {
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                }
                              }
                            },
                            icon: Icon(
                              isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                              color: Colors.white,
                            ),
                            label: Text(
                              isInCart ? 'Remover' : 'Adicionar ao carrinho',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart ? Colors.red : const Color.fromARGB(255, 236, 63, 121),
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
    );
  }
}