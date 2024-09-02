// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/formatadores/formata_moeda.dart';
import 'package:intl/intl.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final String razaoSocialCnpj;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.razaoSocialCnpj,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _productDescription = '';
  String _productBrand = '';
  double _productPrice = 0.0;
  File? _productImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar os dados do produto do Firestore
      var productSnapshot = await FirebaseFirestore.instance
          .collection('distribuidores/${widget.razaoSocialCnpj}/produtos')
          .doc(widget.productId)
          .get();

      if (productSnapshot.exists) {
        var productData = productSnapshot.data()!;
        setState(() {
          _productName = productData['name'];
          _productBrand = productData['marca'] ?? '';
          _productDescription = productData['description'];
          _productPrice = productData['price'];
          _existingImageUrl = productData['imageUrl'];

          // Formatar o preço para exibição correta no campo
          _priceController.text = NumberFormat.currency(
            locale: 'pt_BR',
            symbol: '',
            decimalDigits: 2,
          ).format(_productPrice);
        });
      } else {
        throw 'Produto não encontrado';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do produto: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickProductImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _editProduct() async {
    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Edição?'),
        content: const Text('Tem certeza de que deseja salvar as alterações desse produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (shouldEdit != true) {
      return; // Se o usuário cancelar, simplesmente retorna sem editar
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Inicializar um mapa para as atualizações
        Map<String, dynamic> updateData = {};

        // Verificar se o nome foi alterado
        if (_productName.isNotEmpty) {
          updateData['name'] = _productName;
          updateData['normalized_name'] = _productName.toLowerCase();
        }

        // Verificar se a marca foi alterada
        if (_productBrand.isNotEmpty) {
          updateData['marca'] = _productBrand;
        }

        // Verificar se a descrição foi alterada
        if (_productDescription.isNotEmpty) {
          updateData['description'] = _productDescription;
        }

        // Verificar se o preço foi alterado
        if (_productPrice > 0.0) {
          updateData['price'] = _productPrice;
        }

        // Atualizar a imagem no Firebase Storage se uma nova imagem foi escolhida
        if (_productImage != null) {
          if (_existingImageUrl != null) {
            // Excluir a imagem antiga do Firebase Storage
            await FirebaseStorage.instance.refFromURL(_existingImageUrl!).delete();
          }
          final fileName = 'distribuidores/${widget.razaoSocialCnpj}/produtos/${widget.productId}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child(fileName);
          await storageRef.putFile(_productImage!);
          String imageUrl = await storageRef.getDownloadURL();
          updateData['imageUrl'] = imageUrl;
        }

        // Atualizar o produto no Firestore se houver alguma alteração
        if (updateData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('distribuidores/${widget.razaoSocialCnpj}/produtos')
              .doc(widget.productId)
              .update(updateData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma alteração detectada.')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar produto: $e')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _productName,
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
                      initialValue: _productBrand,
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
                      initialValue: _productDescription,
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
                        ? Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: _existingImageUrl == null || _existingImageUrl!.isEmpty
                                    ? const Center(
                                        child: Text('Clique para adicionar imagem do produto'),
                                      )
                                    : Image.network(
                                        _existingImageUrl!,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                Container(
                                  color: Colors.black54,
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: const Text(
                                    'Clique na imagem se quiser alterar',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                            ],
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
                      onPressed: _isLoading ? null : _editProduct,
                      child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Editar Produto'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

