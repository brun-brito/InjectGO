// ignore_for_file: library_private_types_in_public_api, prefer_typing_uninitialized_variables, prefer_const_constructors, use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/formatadores/formata_moeda.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:inject_go/subtelas/distribuidores/importa_csv.dart';
import 'package:inject_go/subtelas/distribuidores/meus_produtos.dart';

class ProductRegistrationScreen extends StatefulWidget {
  final String username;
  final String doc;

  const ProductRegistrationScreen({super.key, required this.username, required this.doc});

  @override
  _ProductRegistrationScreenState createState() => _ProductRegistrationScreenState();
}
class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _productDescription = '';
  String _productBrand = '';
  String _productCategory = '';
  double _productPrice = 0.0;
  File? _productImage;
  bool _isLoading = false; 
  var _priceController;
  final ImagePicker _picker = ImagePicker();
  int _availableQuantity = 0;
  int _productLength = 0;
  int _productWidth = 0;
  int _productHeight = 0;
  double _productWeight = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Produto'),
        centerTitle: true,
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
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Quantidade Disponível',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Atenção!'),
                                content: Text('A quantidade disponível será automaticamente descontada a cada compra. Quando chegar a zero, o produto será desativado. Para ativá-lo novamente, será necessário adicionar mais unidades.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Ok'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      _availableQuantity = int.tryParse(value ?? '0') ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty || int.tryParse(value) == null) {
                        return 'Por favor, insira uma quantidade válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Dimensões do Produto',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Atenção!'),
                                content: const Text(
                                  'Comprimento, largura e altura devem ser números inteiros (ex: 10, 20, 30) representado em cm, e o peso pode ser um valor decimal (ex: 0.5, 1.8, 2.2) representado em kg.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Ok'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Comprimento (cm)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (value) {
                            _productLength = int.tryParse(value ?? '0') ?? 0;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Número deve ser inteiro';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Largura (cm)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (value) {
                            _productWidth = int.tryParse(value ?? '0') ?? 0;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Número deve ser inteiro';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Altura (cm)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (value) {
                            _productHeight = int.tryParse(value ?? '0') ?? 0;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Número deve ser inteiro';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Peso (kg)'),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
                          ],
                          onSaved: (value) {
                            String formattedValue = value?.replaceAll(',', '.') ?? '0.0';
                            _productWeight = double.tryParse(formattedValue) ?? 0.0;
                          },
                          validator: (value) {
                            String formattedValue = value?.replaceAll(',', '.') ?? '';
                            if (formattedValue.isEmpty || double.tryParse(formattedValue) == null) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImportCSVScreen(username: widget.username, doc: widget.doc,), // Navegar para a tela de importação CSV
                        ),
                      );
                    },
                    child: const Text('Importar Produtos via CSV'),
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
        return;
      }

      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Buscar a 'razao_social' e 'cnpj' do distribuidor pelo email
        var distribuidorSnapshot = await FirebaseFirestore.instance
            .collection('distribuidores')
            .where('email', isEqualTo: widget.username)
            .limit(1)
            .get();

        if (distribuidorSnapshot.docs.isNotEmpty) {
          var distribuidorData = distribuidorSnapshot.docs.first.data();
          String razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';
          String productId = FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc().id;
          String imageUrl = '';
          if (_productImage != null) {
            final fileName = 'distribuidores/$razaoSocialCnpj/produtos/$productId.jpg';
            final storageRef = FirebaseStorage.instance.ref().child(fileName);
            await storageRef.putFile(_productImage!);
            imageUrl = await storageRef.getDownloadURL();
          }

          await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).set({
            'id': productId,
            'name': primeiraMaiuscula(_productName.trim()),
            'description': _productDescription,
            'marca': primeiraMaiuscula(_productBrand.trim()),
            'categoria': primeiraMaiuscula(_productCategory.trim()),
            'price': _productPrice,
            'imageUrl': imageUrl,
            'username': widget.username,
            'createdAt': Timestamp.now(),
            'disponivel': _availableQuantity > 0,  // Verifica se a quantidade disponível é maior que zero
            'quantidade_disponivel': _availableQuantity,
            'altura': _productHeight,
            'largura': _productWidth,
            'comprimento': _productLength,
            'peso': _productWeight,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto cadastrado com sucesso!')),
          );

          Navigator.push(context,MaterialPageRoute(builder: (context) => MyProductsScreen(username: widget.username)));
        } else {
          throw 'Distribuidor não encontrado';
        }
      } catch (e) {
        // Se ocorrer algum erro no processo, nada será salvo no Firebase e o erro será exibido
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
