// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  final Map<String, bool> _isDeleteIconClicked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
      ),
      body: _buildProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductRegistrationScreen(username: widget.username)),
          );
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
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

        return Column(
          children: [
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
  }

  Stream<QuerySnapshot> _getProductStream(String razaoSocialCnpj) {
    switch (_selectedFilter) {
      case 'name_asc':
        return FirebaseFirestore.instance
            .collection('distribuidores/$razaoSocialCnpj/produtos')
            .orderBy('normalized_name', descending: false)
            .snapshots();
      case 'name_desc':
        return FirebaseFirestore.instance
            .collection('distribuidores/$razaoSocialCnpj/produtos')
            .orderBy('normalized_name', descending: true)
            .snapshots();
      case 'price_asc':
        return FirebaseFirestore.instance
            .collection('distribuidores/$razaoSocialCnpj/produtos')
            .orderBy('price', descending: false)
            .snapshots();
      case 'price_desc':
        return FirebaseFirestore.instance
            .collection('distribuidores/$razaoSocialCnpj/produtos')
            .orderBy('price', descending: true)
            .snapshots();
      default:
        return FirebaseFirestore.instance
            .collection('distribuidores/$razaoSocialCnpj/produtos')
            .snapshots();
    }
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
      context: context, // Aqui o context é passado como argumento
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 30),
            SizedBox(width: 10),Text('Confirmar Exclusão?'),
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
      return; // Se o usuário cancelar, simplesmente retorna sem excluir
    }

    try {
      // Exclui a imagem do produto no Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      // Exclui o documento do produto no Firestore
      await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto excluído com sucesso!')
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao excluir produto')
        )
      );
    }
  }
}

