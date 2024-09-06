// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/formatadores/formata_string.dart';
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
  String _selectedCategory = 'Todas'; // Novo filtro para categoria
  final Map<String, bool> _isDeleteIconClicked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildProductList(), // Lista de produtos
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, 
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductRegistrationScreen(username: widget.username)),
                );
              },
              child:Text('Adiconar Produto'),
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

        String razaoSocialCnpj = snapshot.data!;

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
                          return ListTile(
                            leading: Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(product['name']),
                            subtitle: Text('R\$ ${product['price'].toStringAsFixed(2)}'),
                            trailing: Row(
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
                            onTap: () {},
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

    // Filtro de marca
    if (_selectedBrand != 'Todos') {
      query = query.where('normalized_marca', isEqualTo: primeiraMaiuscula(_selectedBrand.toLowerCase()));
    }

    // Filtro de categoria
    if (_selectedCategory != 'Todas') {
      query = query.where('normalized_category', isEqualTo: primeiraMaiuscula(_selectedCategory.toLowerCase()));
    }

    // Filtro de ordenação (nome ou preço)
    switch (_selectedFilter) {
      case 'name_asc':
        query = query.orderBy('normalized_name', descending: false);
        break;
      case 'name_desc':
        query = query.orderBy('normalized_name', descending: true);
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

    // Obter e normalizar marcas
    List<String> brands = querySnapshot.docs
        .map((doc) => primeiraMaiuscula(doc['normalized_marca'])) // Usa a normalização para exibir
        .toSet()
        .toList();

    // Obter e normalizar categorias
    List<String> categories = querySnapshot.docs
        .map((doc) => primeiraMaiuscula(doc['normalized_category'])) // Usa a normalização para exibir
        .toSet()
        .toList();

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
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
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
}
