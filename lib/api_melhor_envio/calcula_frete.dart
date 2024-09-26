// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EscolherFreteScreen extends StatefulWidget {
  final String cepOrigem;
  final String cepDestino;
  final List<Map<String, dynamic>> produtos;

  const EscolherFreteScreen({
    super.key,
    required this.cepOrigem,
    required this.cepDestino,
    required this.produtos,
  });

  @override
  _EscolherFreteScreenState createState() => _EscolherFreteScreenState();
}

class _EscolherFreteScreenState extends State<EscolherFreteScreen> {
  List<dynamic> freteOptions = [];
  bool isLoading = true;
  String? selectedFreteId;

  @override
  void initState() {
    super.initState();
    _getFreteOptions();
  } 

  // Função para calcular as dimensões totais do pacote com base nos produtos
  Map<String, dynamic> _calcularPacoteConsolidado(List<Map<String, dynamic>> produtos) {
    double alturaTotal = 0.0;
    double larguraMax = 0.0;
    double comprimentoMax = 0.0;
    double pesoTotal = 0.0;

    for (var produto in produtos) {
      alturaTotal += (produto['height'] as num).toDouble(); // Empilhando os produtos, garante que seja double
      larguraMax = larguraMax > (produto['width'] as num).toDouble() 
          ? larguraMax 
          : (produto['width'] as num).toDouble(); // Maior largura
      comprimentoMax = comprimentoMax > (produto['length'] as num).toDouble() 
          ? comprimentoMax 
          : (produto['length'] as num).toDouble(); // Maior comprimento
      pesoTotal += (produto['weight'] as num).toDouble(); // Soma o peso de todos os produtos
    }

    return {
      "height": alturaTotal.toInt(), // Altura total empilhada
      "width": larguraMax.toInt(), // Maior largura encontrada
      "length": comprimentoMax.toInt(), // Maior comprimento encontrado
      "weight": pesoTotal // Peso total (mantém como double para maior precisão)
    };
  }


  Future<void> _getFreteOptions() async {
    const apiUrl = 'https://melhorenvio.com.br/api/v2/me/shipment/calculate';
    String? token = dotenv.env['TOKEN_API_ENVIO'];

    // Calcular o pacote consolidado a partir dos produtos
    final pacoteConsolidado = _calcularPacoteConsolidado(widget.produtos);

    final body = jsonEncode({
      "from": {"postal_code": widget.cepOrigem},
      "to": {"postal_code": widget.cepDestino},
      "package": pacoteConsolidado, // Enviar o pacote consolidado ao invés dos produtos
    });

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        setState(() {
          freteOptions = jsonDecode(response.body); // Parseando a resposta
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao calcular o frete: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        // Mostrar mensagem de erro se necessário
      });
      debugPrint('Erro ao obter fretes: $e');
    }
  }

  // Função para renderizar a lista de frete
  Widget _buildFreteOptions() {
    if (freteOptions.isEmpty) {
      return const Center(child: Text("Nenhum serviço de frete disponível."));
    }

    return ListView.builder(
      itemCount: freteOptions.length,
      itemBuilder: (context, index) {
        final frete = freteOptions[index];
        final company = frete['company'];

        // Verifica se existe um erro no serviço de frete
        if (frete.containsKey('error')) {
          return const SizedBox.shrink(); // Retorna um widget vazio se houver erro
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Define margens para os cards
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Adiciona padding dentro do card
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Imagem da transportadora com tamanho reduzido e proporção adequada
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Image.network(
                    company['picture'],
                    fit: BoxFit.contain, // Mantém a proporção da imagem
                  ),
                ),
                const SizedBox(width: 16), // Espaço entre a imagem e os textos
                // Coluna de informações (Nome do serviço, preço, prazo)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${utf8.decode(company['name'].toString().runes.toList())} - ${utf8.decode(frete['name'].toString().runes.toList())}', // Decodifica os textos
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4), // Espaço entre o nome e o preço
                      Text(
                        'Preço: ${frete['currency']} ${frete['price']}',
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 4), // Espaço entre o preço e o prazo de entrega
                      Text(
                        'Prazo de Entrega: ${frete['delivery_time']} dias úteis',
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Radio button para selecionar o frete
                Radio<String>(
                  value: frete['id'].toString(),  // Certifique-se de que o valor seja uma string
                  groupValue: selectedFreteId,
                  activeColor: const Color.fromARGB(255, 236, 63, 121),
                  onChanged: (String? value) {
                    setState(() {
                      selectedFreteId = value;  // O valor do frete selecionado
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha o Serviço de Frete"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)))
          : _buildFreteOptions(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: 
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 236, 63, 121),
            foregroundColor: Colors.white
          ),
          onPressed: selectedFreteId == null
            ? null
            : () {
                  final selectedFrete = freteOptions.firstWhere((frete) => frete['id'].toString() == selectedFreteId);
                  Navigator.pop(context, selectedFrete);
              },
          child: const Text("Selecionar Frete"),
        ),
      ),
    );
  }
// TODO: LEVAR EM CONSIDERAÇÃO QUANTIDADE NO CÁLCULO
}