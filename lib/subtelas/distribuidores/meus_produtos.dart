// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';
import 'package:inject_go/subtelas/distribuidores/edita_produto.dart';
import 'package:inject_go/subtelas/distribuidores/cadastra_produto.dart';

class MyProductsScreen extends StatefulWidget {
  final String username;

  const MyProductsScreen({super.key, required this.username});

  @override
  _MyProductsScreenState createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  String _selectedFilter = 'name_asc';
  String _selectedBrand = 'Todos';
  String _selectedCategory = 'Todas';
  String razaoSocialCnpj = '';
  final Map<String, bool> _isDeleteIconClicked = {};
  final String defaultImageUrl = dotenv.env['PATH_IMAGE_DEFAULT'] ?? '';
  bool _isSelectionMode = false;
  ValueNotifier<List<String>> selectedProductsNotifier = ValueNotifier([]);

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreenDistribuidor(username: widget.username),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildProductList(), // Lista de produtos
          ),
          if (_isSelectionMode) // Mostra o botão de deletar apenas no modo de seleção
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: selectedProductsNotifier,
                builder: (context, selectedProducts, _) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: selectedProducts.isEmpty ? null : _deleteSelectedProducts,
                    icon: Icon(Icons.delete, color: Colors.white), // Ícone de lixeira
                    label: const Text('Excluir Selecionados'), // Texto do botão
                  );
                },
              )
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductRegistrationScreen(username: widget.username, doc: razaoSocialCnpj)),
                );
              },
              child: Text('Adicionar Produto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<String>(
      future: _getRazaoSocialCnpj(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        razaoSocialCnpj = snapshot.data!;

        return FutureBuilder<Map<String, List<String>>>(
          future: _fetchAvailableFilters(razaoSocialCnpj), // Atualizado para buscar marca e categoria
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar filtros: ${snapshot.error}'));
            }

            Map<String, List<String>> filters = snapshot.data!;
            List<String> brands = filters['brands']!;
            List<String> categories = filters['categories']!;

            return Column(
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
                              items: brands.map((brand) {
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
                              items: categories.map((category) {
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Para alinhar os dois botões
                    children: [
                      Expanded(
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
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white, 
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = !_isSelectionMode; 
                          });
                        },
                        icon: Icon(
                          _isSelectionMode ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                          color: Colors.white,
                        ),
                        label: const Text('Selecionar'), 
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getProductStream(razaoSocialCnpj),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('Nenhum produto cadastrado.'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var product = snapshot.data!.docs[index];
                          bool isSelected = selectedProductsNotifier.value.contains(product['id']);

                          return ListTile(
                            leading: _isSelectionMode
                            ? StatefulBuilder(
                                builder: (context, localSetState) {
                                  return ValueListenableBuilder<List<String>>(
                                    valueListenable: selectedProductsNotifier,
                                    builder: (context, selectedProducts, _) {
                                      return Checkbox(
                                        value: selectedProducts.contains(product['id']),
                                        onChanged: (isChecked) {
                                          localSetState(() {
                                            _onProductSelected(product['id'], isChecked);
                                          });
                                        },
                                        activeColor: Color.fromARGB(255, 236, 63, 121),
                                      );
                                    },
                                  );
                                },
                              )
                            : Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(product['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('R\$ ${product['price'].toStringAsFixed(2)}'),
                                Text(
                                  'Quantidade disponível: ${product['quantidade_disponivel'] ?? 0}',
                                  style: TextStyle(
                                    color: (product['quantidade_disponivel'] ?? 0) == 0 ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            trailing: _isSelectionMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProductScreen(
                                                productId: product['id'],
                                                razaoSocialCnpj: razaoSocialCnpj,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      StatefulBuilder(
                                        builder: (context, setState) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: _isDeleteIconClicked[product['id']] == true ? Colors.red : null,
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _isDeleteIconClicked[product['id']] = true; // Muda o ícone para vermelho
                                              });

                                              await _deleteProduct(context, product['id'], product['imageUrl'], razaoSocialCnpj);

                                              setState(() {
                                                _isDeleteIconClicked.remove(product['id']); // Restaura a cor original
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                            onTap: _isSelectionMode
                                ? () {
                                    setState(() {
                                      _onProductSelected(product['id'], !isSelected); // Alterna a seleção do produto ao tocar
                                    });
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getProductStream(String razaoSocialCnpj) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('distribuidores/$razaoSocialCnpj/produtos');

    // Filtros de marca
    if (_selectedBrand != 'Todos') {
      query = query.where('marca', isEqualTo: primeiraMaiuscula(_selectedBrand.toLowerCase()));
    }

    // Filtro de categoria
    if (_selectedCategory != 'Todas') {
      query = query.where('categoria', isEqualTo: primeiraMaiuscula(_selectedCategory.toLowerCase()));
    }

    // Filtro de ordenação (nome ou preço)
    switch (_selectedFilter) {
      case 'name_asc':
        query = query.orderBy('name', descending: false);
        break;
      case 'name_desc':
        query = query.orderBy('name', descending: true);
        break;
      case 'price_asc':
        query = query.orderBy('price', descending: false);
        break;
      case 'price_desc':
        query = query.orderBy('price', descending: true);
        break;
    }

    return query.snapshots();
  }

  Future<Map<String, List<String>>> _fetchAvailableFilters(String razaoSocialCnpj) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('distribuidores/$razaoSocialCnpj/produtos')
        .get();

    // Obter marcas
    List<String> brands = querySnapshot.docs
        .map((doc) => primeiraMaiuscula(doc['marca']))
        .toSet()
        .toList();

    if (!brands.contains(_selectedBrand)) {
      _selectedBrand = 'Todos';
    }

    // Obter categorias
    List<String> categories = querySnapshot.docs
        .map((doc) => primeiraMaiuscula(doc['categoria']))
        .toSet()
        .toList();

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Todas';
    }

    // Adicionar 'Todos' e 'Todas' no início das listas para permitir filtro global
    brands.insert(0, 'Todos');
    categories.insert(0, 'Todas');

    return {'brands': brands, 'categories': categories};
  }

  Future<String> _getRazaoSocialCnpj() async {
    var distribuidorSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .where('email', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (distribuidorSnapshot.docs.isNotEmpty) {
      var distribuidorData = distribuidorSnapshot.docs.first.data();
      return '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';
    } else {
      throw 'Distribuidor não encontrado';
    }
  }

  Future<void> _deleteProduct(BuildContext context, String productId, String imageUrl, String razaoSocialCnpj) async {
    final shouldDelete = await showDialog<bool>(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Confirmar Exclusão?'),
          ],
        ),
        content: const Text('Tem certeza de que deseja excluir este produto? Esta ação não poderá ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      if (imageUrl != defaultImageUrl) {
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      }
      await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir produto')),
      );
    }
  }

  void _onProductSelected(String productId, bool? isSelected) {
    if (isSelected == true) {
      // Adiciona o produto à lista de selecionados
      selectedProductsNotifier.value = [...selectedProductsNotifier.value, productId];
    } else {
      // Remove o produto da lista de selecionados
      selectedProductsNotifier.value = selectedProductsNotifier.value.where((id) => id != productId).toList();
    }
  }

  Future<void> _deleteSelectedProducts() async {
    final selectedProducts = selectedProductsNotifier.value; // Acessa a lista de produtos selecionados
    for (var productId in selectedProducts) {
      await _deleteProductById(productId);
    }
    // Após a exclusão, limpa a lista de produtos selecionados
    selectedProductsNotifier.value = [];
  }

  Future<void> _deleteProductById(String productId) async {
    var productSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores/$razaoSocialCnpj/produtos')
        .doc(productId)
        .get();
    var productData = productSnapshot.data();
    var imageUrl = productData?['imageUrl'] ?? '';

    if (imageUrl != defaultImageUrl) {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    }
    await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).delete();
  }

}
