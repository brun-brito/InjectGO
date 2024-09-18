// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inject_go/mercado_pago/comprar_produto_mp.dart';

class AddressFormScreen extends StatefulWidget {
  final String initPoint;
  final List<String> productIds;  // Agora você passa uma lista de IDs
  final String userEmail;
  final Position posicao;

  const AddressFormScreen({
    super.key,
    required this.initPoint,
    required this.productIds,  // Recebe a lista de IDs de produtos
    required this.userEmail,
    required this.posicao,
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

  bool _isLoading = false;
  bool _isFieldsEnabled = false;

  // Função para buscar endereço pelo CEP
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
          _isFieldsEnabled = true;  // Habilita os campos para alteração
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

  @override
  Widget build(BuildContext context) {
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
                  // Se o CEP for apagado ou incompleto, limpar os campos
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
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        labelText: 'Bairro*',
                      ),
                      enabled: _isFieldsEnabled,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade*',
                      ),
                      enabled: _isFieldsEnabled,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ufController,
                      decoration: const InputDecoration(
                        labelText: 'UF*',
                      ),
                      enabled: _isFieldsEnabled,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _numeroController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número*',
                      ),
                      enabled: _isFieldsEnabled,
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 236, 63, 121), 
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isFieldsEnabled ? _confirmarEndereco : null,
                      child: const Text('Confirmar Endereço'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Função chamada ao confirmar o endereço
  void _confirmarEndereco() {  
    if (_numeroController.text.isEmpty) {
      _showError("O campo Número é obrigatório.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPurchaseScreen(
          initPoint: widget.initPoint,  // O link para o pagamento
          productIds: widget.productIds,  // Passa a lista de IDs dos produtos
          userEmail: widget.userEmail,  // Passa o email do usuário
          endereco: {
            'cep': _cepController.text,
            'rua': _ruaController.text,
            'numero': _numeroController.text,
            'complemento': _complementoController.text,
            'bairro': _bairroController.text,
            'cidade': _cidadeController.text,
            'uf': _ufController.text,
          },
          posicao: widget.posicao,
        ),
      ),
    );
  }
}