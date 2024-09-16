// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors, curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/formatadores/formata_moeda.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:inject_go/mercado_pago/edita_produto_mp.dart';
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
  String _productCategory = '';
  double _productPrice = 0.0;
  File? _productImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _disponivel = true;
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  var firestore = FirebaseFirestore.instance;
  var storage = FirebaseStorage.instance;
  final String defaultImageUrl = dotenv.env['PATH_IMAGE_DEFAULT'] ?? '';
  int _productQuantity = 1;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var productSnapshot = await firestore
          .collection('distribuidores/${widget.razaoSocialCnpj}/produtos')
          .doc(widget.productId)
          .get();

      if (productSnapshot.exists) {
        var productData = productSnapshot.data()!;
        setState(() {
          _productName = productData['name'];
          _productBrand = productData['marca'] ?? '';
          _productCategory = productData['categoria'] ?? '';
          _productDescription = productData['description'];
          _productPrice = productData['price'];
          _existingImageUrl = productData['imageUrl'];
          _disponivel = productData['disponivel'] ?? true;
          _productQuantity = productData['quantidade_disponivel'];
          _quantityController.text = _productQuantity.toString();

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
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> updateData = {};

        if (_productName.isNotEmpty) {
          updateData['name'] = primeiraMaiuscula(_productName.trim());
        }

        if (_productBrand.isNotEmpty) {
          updateData['marca'] = primeiraMaiuscula(_productBrand.trim());
        }

        if (_productCategory.isNotEmpty) {
          updateData['categoria'] = primeiraMaiuscula(_productCategory.trim());
        }

        if (_productDescription.isNotEmpty) {
          updateData['description'] = _productDescription;
        }

        if (_productPrice > 0.0) {
          updateData['price'] = _productPrice;
        }

        if(_productQuantity > 0)
          updateData['disponivel'] = _disponivel;
        
        updateData['ultima_edicao'] = Timestamp.now();

        updateData['quantidade_disponivel'] = _productQuantity;

        // Lógica de atualização da imagem
        if (_productImage != null) {
          final fileName = 'distribuidores/${widget.razaoSocialCnpj}/produtos/${widget.productId}.jpg';
          final storageRef = storage.ref().child(fileName);

          // Faça o upload da nova imagem
          await storageRef.putFile(_productImage!);
          String imageUrl = await storageRef.getDownloadURL();
          updateData['imageUrl'] = imageUrl;

          // Excluir a imagem anterior apenas se ela não for a imagem padrão
          if (_existingImageUrl != null &&
              _existingImageUrl != defaultImageUrl && 
              _existingImageUrl!.isNotEmpty) {
            await storage.refFromURL(_existingImageUrl!).delete();
          }
        }

        final distributorDoc = await firestore
            .collection('distribuidores')
            .doc(widget.razaoSocialCnpj)
            .collection('produtos')
            .doc(widget.productId)
            .get();

        final distributorInfoDoc = await firestore
            .collection('distribuidores')
            .doc(widget.razaoSocialCnpj)
            .get();

        final distributorAccessToken = distributorInfoDoc.data()!['credenciais_mp']['access_token'];
        final produtoMpId = distributorDoc.data()!['produto_mp']['id'];
        final marketplace = dotenv.env['MERCADO_PAGO_ACCESS_TOKEN'];
        final String? taxaStr = dotenv.env['TAXA_MERCADO_PAGO'];
        final double? taxa = double.tryParse(taxaStr ?? '0');
        final fee = _productPrice * taxa!;

        final mpEditProduct = EditProductMpScreen(
          mpProductId: produtoMpId,    // id do Mercado Pago
          productId: widget.productId, // id do Firestore
          updatedName: _productName,
          updatedDescription: _productDescription,
          updatedImageUrl: _productImage != null ? updateData['imageUrl'] : _existingImageUrl!,
          updatedCategory: _productCategory,
          updatedPrice: _productPrice,
          updatedMarketplaceFee: fee,
          distributorAccessToken: distributorAccessToken,
          marketplace: marketplace,
        );

        bool successInMp = await mpEditProduct.editProductInMp();
        if (successInMp) {
          if (updateData.isNotEmpty) {
            await firestore
                .collection('distribuidores/${widget.razaoSocialCnpj}/produtos')
                .doc(widget.productId)
                .update(updateData);

            await firestore
                .collection('distribuidores/${widget.razaoSocialCnpj}/produtos')
                .doc(widget.productId)
                .update({
              'produto_mp.marketplace_fee': fee,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produto atualizado com sucesso!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nenhuma alteração detectada.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao atualizar produto no Mercado Pago.')),
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
                      decoration: const InputDecoration(labelText: 'Nome'),
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
                      decoration: const InputDecoration(labelText: 'Marca'),
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
                      initialValue: _productCategory, // Campo de categoria
                      decoration: const InputDecoration(labelText: 'Categoria (Toxina, Fios, Bioestimuladores...)'),
                      onSaved: (value) {
                        _productCategory = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a categoria do produto';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _productDescription,
                      decoration: const InputDecoration(labelText: 'Descrição'),
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
                        labelText: 'Preço',
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
                    // Quantidade disponível
                    // Quantidade disponível
Row(
  children: [
    IconButton(
      icon: Icon(Icons.remove),
      onPressed: () {
        setState(() {
          if (_productQuantity > 0) {
            _productQuantity--;
            _quantityController.text = _productQuantity.toString();  // Atualiza o campo de texto
          }
          // Se a quantidade for 0, desativa o produto
          if (_productQuantity == 0) {
            _disponivel = false; // Desativa o produto
          }
        });
      },
    ),
    Expanded(
      child: TextFormField(
        controller: _quantityController,  // Usa o controlador
        decoration: const InputDecoration(
          labelText: 'Quantidade disponível',
        ),
        keyboardType: TextInputType.number,
        onSaved: (value) {
          _productQuantity = int.tryParse(value ?? '0') ?? 0;
          if (_productQuantity == 0) {
            _disponivel = false;  // Desativa o produto automaticamente
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty || int.tryParse(value) == null) {
            return 'Por favor, insira uma quantidade válida';
          }
          return null;
        },
      ),
    ),
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () {
        setState(() {
          _productQuantity++;
          _quantityController.text = _productQuantity.toString();  // Atualiza o campo de texto
          // Se a quantidade for maior que 0, o produto volta a estar disponível
          if (_productQuantity > 0) {
            _disponivel = true;  // Reativa o produto
          }
        });
      },
    ),
  ],
),

                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Produto disponível'),
                      value: _disponivel,
                      onChanged: (bool value) {
                        setState(() {
                          _disponivel = value;
                        });
                      },
                      activeColor: const Color.fromARGB(255, 236, 63, 121),  // Cor alterada
                      controlAffinity: ListTileControlAffinity.leading,  // Botão à esquerda
                    ),
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
