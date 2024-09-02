// ignore_for_file: library_private_types_in_public_api, prefer_typing_uninitialized_variables, prefer_const_constructors, use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/formatadores/formata_moeda.dart';

class ProductRegistrationScreen extends StatefulWidget {
  final String username;

  const ProductRegistrationScreen({super.key, required this.username});

  @override
  _ProductRegistrationScreenState createState() => _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _productDescription = '';
  String _productBrand = '';
  double _productPrice = 0.0;
  File? _productImage;
  bool _isLoading = false; 
  var _priceController;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Produto'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nome do Produto'),
                    onSaved: (value) {
                      _productName = value ?? '';
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do produto';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Marca do Produto'),
                    onSaved: (value) {
                      _productBrand = value ?? '';
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a marca do produto';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Descrição do Produto'),
                    onSaved: (value) {
                      _productDescription = value ?? '';
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a descrição do produto';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Preço do Produto',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      CurrencyInputFormatter(),
                    ],
                    onSaved: (value) {
                      // Remove pontos de milhares e substitui a vírgula por ponto
                      String sanitizedValue = value?.replaceAll('.', '').replaceAll(',', '.') ?? '0.0';
                      _productPrice = double.tryParse(sanitizedValue) ?? 0.0;
                    },
                    validator: (value) {
                      // Remove pontos de milhares e substitui a vírgula por ponto
                      String sanitizedValue = value?.replaceAll('.', '').replaceAll(',', '.') ?? '';
                      
                      if (sanitizedValue.isEmpty || double.tryParse(sanitizedValue) == null) {
                        return 'Por favor, insira um preço válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _pickProductImage(),
                    child: _productImage == null
                        ? Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text('Clique para adicionar imagem do produto'),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.file(
                                _productImage!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: const Text(
                                  'Clique na imagem se quiser alterar',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                    ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink, 
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProductImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_productImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, insira uma imagem do produto')),
        );
        return; // Evita o salvamento se a imagem não estiver presente
      }

      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Buscar a 'razao_social' e 'cnpj' do distribuidor pelo email
        var distribuidorSnapshot = await FirebaseFirestore.instance
            .collection('distribuidores')
            .where('email', isEqualTo: widget.username)
            .limit(1)
            .get();

        if (distribuidorSnapshot.docs.isNotEmpty) {
          var distribuidorData = distribuidorSnapshot.docs.first.data();
          String razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';

          // Gerando um ID único para o produto
          String productId = FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc().id;

          String imageUrl = '';
          if (_productImage != null) {
            final fileName = 'distribuidores/$razaoSocialCnpj/produtos/$productId.jpg';
            final storageRef = FirebaseStorage.instance.ref().child(fileName);
            await storageRef.putFile(_productImage!);
            imageUrl = await storageRef.getDownloadURL();
          }

          // Salvando o produto na coleção correta
          await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).set({
            'id': productId,
            'name': _productName,
            'normalized_name': _productName.toLowerCase(),
            'description': _productDescription,
            'marca': _productBrand, 
            'price': _productPrice,
            'imageUrl': imageUrl,
            'username': widget.username,
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto cadastrado com sucesso!')),
          );

          Navigator.pop(context);
        } else {
          throw 'Distribuidor não encontrado';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar produto: $e')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }
}
