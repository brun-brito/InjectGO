// ignore_for_file: library_private_types_in_public_api, prefer_typing_uninitialized_variables, non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:inject_go/api_melhor_envio/calcula_frete.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:inject_go/mercado_pago/comprar_produto_mp.dart';
import 'dart:convert';
import 'package:inject_go/mercado_pago/cria_preferencia_mp.dart';

class AddressFormScreen extends StatefulWidget {
  final List<DocumentSnapshot> cartProducts; // Produtos do carrinho
  final String email;
  final Position posicao;
  final Map<DocumentSnapshot, int> productQuantities; // Quantidades de cada produto

  const AddressFormScreen({
    super.key,
    required this.cartProducts,
    required this.email,
    required this.posicao,
    required this.productQuantities,
  });

  @override
  _AddressFormScreenState createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();

  final MercadoPagoService mercadoPagoService = MercadoPagoService(); // Serviço do Mercado Pago
  bool _isLoading = false;
  bool _isFieldsEnabled = false;
  double? frete;
  String? selectedFreteId;
  String? responsavel;
  int? tempo_entrega;
  var selectedFrete;

  Map<String, double> calcularDimensoesCaixa(List<Map<String, dynamic>> produtos) {
    double alturaCaixa = 0;
    double larguraMax = 0;
    double comprimentoCaixa = 0;
    double pesoTotal = 0;

    for (var produto in produtos) {
      alturaCaixa += (produto['height'] as num).toDouble();
      larguraMax = larguraMax > (produto['width'] as num).toDouble() 
                  ? larguraMax 
                  : (produto['width'] as num).toDouble();
      comprimentoCaixa += (produto['length'] as num).toDouble();
      pesoTotal += (produto['weight'] as num).toDouble();
    }

    return {
      'altura': alturaCaixa,
      'largura': larguraMax,
      'comprimento': comprimentoCaixa,
      'peso_aproximado': pesoTotal,
    };
  }

  Future<void> _buscarCep(String cep) async {
    final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!data.containsKey('erro')) {
        setState(() {
          _ruaController.text = data['logradouro'];
          _bairroController.text = data['bairro'];
          _cidadeController.text = data['localidade'];
          _ufController.text = data['uf'];
          _isFieldsEnabled = true; // Habilita os campos
        });
      } else {
        _limparCampos();
        _showError("CEP inválido.");
      }
    } else {
      _limparCampos();
      _showError("Erro ao buscar o CEP.");
    }
  }

  void _limparCampos() {
    setState(() {
      _ruaController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _ufController.clear();
      _numeroController.clear();
      _complementoController.clear();
      _isFieldsEnabled = false;
    });
  }

  // Função para mostrar erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>> _buscarInfoDistribuidor() async {
    final distribuidorId = widget.cartProducts.first.reference.parent.parent!.id;

    // Busca o documento do distribuidor no Firestore
    final distribuidorDoc = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distribuidorId)
        .get();

    if (distribuidorDoc.exists) {
      // Retorna um mapa com todas as informações necessárias do distribuidor
      return {
        'id': distribuidorId,
        'cep': distribuidorDoc['cep'],
        'accessToken': distribuidorDoc['credenciais_mp']['access_token'],
      };
    } else {
      throw Exception('Distribuidor não encontrado');
    }
  }

  // Função para calcular o frete
  Future<void> _calcularFrete() async {
    final distribuidorInfo = await _buscarInfoDistribuidor();
    final cepDestino = _cepController.text; // CEP do cliente
    final cepOrigem = distribuidorInfo['cep']; // CEP do distribuidor

    final produtos = widget.cartProducts.map((produto) {
      return {
        "id": produto.id.toString(),
        "width": (produto['largura'] as int),
        "height": (produto['altura'] as int),
        "length": (produto['comprimento'] as int),
        "weight": (produto['peso'] as double),
        "insurance_value": (produto['price'] as double),
        "quantity": (widget.productQuantities[produto] ?? 1),
      };
    }).toList();

    try {
      // Navega para a tela de escolha de frete, passando os dados
      selectedFrete = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EscolherFreteScreen(
            cepOrigem: cepOrigem,
            cepDestino: cepDestino,
            produtos: produtos,
          ),
        ),
      );

    if (selectedFrete != null) {
      frete = double.tryParse(selectedFrete['price'].toString()) ?? 0.0;
      tempo_entrega = selectedFrete['delivery_time'];
      responsavel = selectedFrete['company']['name'];

      setState(() {
        selectedFreteId = selectedFrete['id'].toString();
      });
    }
    } catch (e) {
      _showError("Erro ao calcular o frete.");
      debugPrint('Erro: $e');
    }
  }

  // Função para criar a preferência no Mercado Pago
  Future<void> _criarPreferencia() async {
    setState(() {
      _isLoading = true;  // Inicia o estado de carregamento
    });

    try {
      final distribuidorInfo = await _buscarInfoDistribuidor();
      List<Map<String, dynamic>> items = widget.cartProducts.map((product) {
        double price = (product['price'] as num).toDouble();
        final int quantity = widget.productQuantities[product] ?? 1;
        return {
          "id": product.id,
          "title": product['name'],
          "description": product['description'],
          "picture_url": product['imageUrl'],
          "category_id": product['categoria'],
          "quantity": quantity,
          "currency_id": "BRL",
          "unit_price": price,
          'distribuidorId': distribuidorInfo['id'],
          'accessTokenVendedor': distribuidorInfo['accesToken'],
          "width": product['largura'] as int,
          "height": product['altura'] as int,
          "length": product['comprimento'] as int,
          "weight": product['peso'] as double,
        };
      }).toList();

      final dimensoesCaixa = calcularDimensoesCaixa(items);

      // Cria a preferência no Mercado Pago com os produtos e frete
      final response = await mercadoPagoService.criarPreferenciaCarrinho(
        cartProducts: items,
        accessTokenVendedor: distribuidorInfo['accessToken'], // Ajustar conforme necessário
        distribuidorId: distribuidorInfo['id'], // Ajustar conforme necessário
        profissionalId: widget.email,
        frete: frete ?? 0.0, // Passa o frete calculado
      );

      // Navegar para a tela de pagamento com o initPoint
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductPurchaseScreen(
            initPoint: response['init_point'], // Link gerado para o pagamento
            endereco: {
              'cep': _cepController.text,
              'rua': _ruaController.text,
              'numero': _numeroController.text,
              'complemento': _complementoController.text,
              'bairro': _bairroController.text,
              'cidade': _cidadeController.text,
              'uf': _ufController.text,
            },
            orderId: response['order_id'],
            productIds: widget.cartProducts.map((product) => product.id).toList(),
            posicao: widget.posicao,
            userEmail: widget.email,
            quantidades: widget.productQuantities,
            envio: {
              'frete': frete,
              'tempo_previsto': tempo_entrega,
              'responsavel': responsavel,
              'dimensoes_caixa': dimensoesCaixa,
              'id_responsavel': selectedFreteId
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;  // Para o estado de carregamento em caso de erro
      });
      _showError("Erro ao criar link de pagamento. Por favor, tente novamente.");  // Exibe mensagem de erro
      debugPrint('Erro ao criar preferência: $e');
    } finally {
      setState(() {
        _isLoading = false;  // Para o estado de carregamento
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFreteGratis = selectedFreteId == 'frete_gratis';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endereço de Entrega'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                hintText: 'Digite seu CEP',
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (value) {
                if (value.length == 8) {
                  setState(() {
                    _isLoading = true;
                  });
                  _buscarCep(value).then((_) {
                    setState(() {
                      _isLoading = false;
                    });
                  });
                } else if (value.length < 8) {
                  _limparCampos();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121))
            else
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _ruaController,
                      decoration: const InputDecoration(
                        labelText: 'Rua*',
                      ),
                      enabled: _isFieldsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isLoading = false;
                          selectedFreteId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        labelText: 'Bairro*',
                      ),
                      enabled: _isFieldsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isLoading = false;
                          selectedFreteId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade*',
                      ),
                      enabled: _isFieldsEnabled,onChanged: (value) {
                        setState(() {
                          _isLoading = false;
                          selectedFreteId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ufController,
                      decoration: const InputDecoration(
                        labelText: 'UF*',
                      ),
                      enabled: _isFieldsEnabled,onChanged: (value) {
                        setState(() {
                          _isLoading = false;
                          selectedFreteId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _numeroController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número*',
                      ),
                      enabled: _isFieldsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isLoading = false;
                          selectedFreteId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _complementoController,
                      decoration: const InputDecoration(
                        labelText: 'Complemento (opcional)',
                      ),
                      enabled: _isFieldsEnabled,
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isFieldsEnabled
                              ? () async {
                                  if (selectedFreteId == null) {
                                    if (_confirmarEndereco()) {
                                      try {
                                        await _calcularFrete();
                                      } catch (e) {
                                        _showError("Erro ao calcular o frete. Tente novamente mais tarde");
                                      }
                                    }
                                  } else {
                                    try {
                                      setState(() {
                                        selectedFreteId = null;
                                      });
                                      await _calcularFrete();
                                    } catch (e) {
                                      _showError("Erro ao editar o frete. Tente novamente mais tarde");
                                    }
                                  }
                                }
                              : null,
                          child: Text(
                            selectedFreteId == null ? 'Calcular Frete' : 'Editar Frete Escolhido',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Exibir o frete escolhido
                        if (selectedFreteId != null)
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Frete Escolhido:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: isFreteGratis ?
                                    const Icon(
                                      Icons.delivery_dining,
                                      size: 90,
                                      color: Colors.green,
                                    )
                                  : Image.network(
                                      selectedFrete['company']['picture'] ?? 'https://via.placeholder.com/50',
                                      fit: BoxFit.contain,
                                    ),
                                ),
                                Text(
                                  isFreteGratis
                                      ? 'Serviço: Entrega Rápida'
                                      : 'Serviço: ${decodeUtf8String(selectedFrete['name'])}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isFreteGratis
                                      ? 'Empresa: Entrega Rápida'
                                      : 'Empresa: ${decodeUtf8String(selectedFrete['company']['name'])}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                isFreteGratis
                                    ? const Text(
                                        'Preço: Frete grátis!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      )
                                    : Text(
                                        'Preço: R\$ ${selectedFrete['price']}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                      ),
                                const SizedBox(height: 4),
                                Text(
                                  isFreteGratis
                                      ? 'Prazo de Entrega: até 5 horas úteis'
                                      : 'Prazo de Entrega: até ${selectedFrete['delivery_time']} dias úteis',
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 236, 63, 121),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: (_isFieldsEnabled && frete != null && selectedFreteId != null && !_isLoading)
                          ? () async {
                              try {
                                setState(() {
                                  _isLoading = true; // Defina o estado de carregamento
                                });
                                await _criarPreferencia();
                              } catch (e) {
                                _showError("Erro ao criar link de pagamento. Tente novamente mais tarde");
                              } finally {
                                setState(() {
                                  _isLoading = false; // Finalize o estado de carregamento
                                });
                              }
                            }
                          : null, // Desabilita o botão se as condições não forem atendidas
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ir para Pagamento'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Função chamada ao confirmar o endereço e calcular o frete
  bool _confirmarEndereco() {
    if (_numeroController.text.isEmpty) {
      _showError("O campo Número é obrigatório.");
      return false;
    }

    if (_cepController.text.isEmpty || _cepController.text.length != 8) {
      _showError("CEP inválido. Certifique-se de que o CEP contém 8 dígitos.");
      return false;
    }
    if (_ruaController.text.isEmpty) {
      _showError("O campo Rua é obrigatório.");
      return false;
    }
    if (_bairroController.text.isEmpty) {
      _showError("O campo Bairro é obrigatório.");
      return false;
    }
    if (_cidadeController.text.isEmpty) {
      _showError("O campo Cidade é obrigatório.");
      return false;
    }
    if (_ufController.text.isEmpty || _ufController.text.length != 2) {
      _showError("O campo UF é obrigatório e deve conter 2 letras.");
      return false;
    }
    if (_numeroController.text.isEmpty) {
      _showError("O campo Número é obrigatório.");
      return false;
    }
    return true;
  }
}