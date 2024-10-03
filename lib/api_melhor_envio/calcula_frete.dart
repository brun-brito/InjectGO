// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures, use_build_context_synchronously

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

  // Função para calcular as dimensões totais do pacote com base nos produtos e suas quantidades
  Map<String, dynamic> _calcularPacoteConsolidado(List<Map<String, dynamic>> produtos) {
    double alturaTotal = 0.0;
    double larguraMax = 0.0;
    double comprimentoMax = 0.0;
    double pesoTotal = 0.0;

    for (var produto in produtos) {
      int quantidade = produto['quantity'] ?? 1;  // Considera a quantidade de cada produto

      // Multiplica as dimensões e o peso pela quantidade de produtos
      alturaTotal += (produto['height'] as num).toDouble() * quantidade; // Empilhando os produtos
      larguraMax = larguraMax > (produto['width'] as num).toDouble() 
          ? larguraMax 
          : (produto['width'] as num).toDouble(); // Maior largura
      comprimentoMax = comprimentoMax > (produto['length'] as num).toDouble() 
          ? comprimentoMax 
          : (produto['length'] as num).toDouble(); // Maior comprimento
      pesoTotal += (produto['weight'] as num).toDouble() * quantidade; // Soma o peso de todos os produtos
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
        });
        // Verifica a distância entre origem e destino
        String apiKey = '';
        if (Theme.of(context).platform == TargetPlatform.android)
          apiKey = dotenv.env['API_KEY_GEO_ANDROID']!;
        else if (Theme.of(context).platform == TargetPlatform.iOS)
          apiKey = dotenv.env['API_KEY_GEO_IOS']!;
        final String directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.cepOrigem}&destination=${widget.cepDestino}&key=$apiKey&mode=driving';
        final distanceResponse = await http.get(Uri.parse(directionsUrl));
        final distanceData = jsonDecode(distanceResponse.body);

        if (distanceData['status'] == 'OK') {
          var legs = distanceData['routes'][0]['legs'][0];
          double distanceInKm = double.parse(legs['distance']['text'].replaceAll(',', '.').split(' ')[0]);

          // Se a distância for menor ou igual a 30 km, adiciona a opção de frete grátis
          if (distanceInKm <= 30) {
            freteOptions.add({
              'id': 'frete_gratis',
              'price': 0.0,
              'delivery_time': 0,
              'name': 'Frete Grátis - Entrega no mesmo dia',
              'company': {'name': 'Entrega Rápida'},
            });
          }
        }

        setState(() {
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

    freteOptions.sort((a, b) {
      if (a['id'] == 'frete_gratis') return -1; // Coloca o frete grátis no topo
      if (b['id'] == 'frete_gratis') return 1;
      return 0;
    });

    return ListView.builder(
      itemCount: freteOptions.length,
      itemBuilder: (context, index) {
        final frete = freteOptions[index];
        final company = frete['company'];
        final isFreteGratis = frete['id'] == 'frete_gratis';

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
                  child: isFreteGratis
                      ? const Icon(
                          Icons.delivery_dining,
                          size: 40,
                          color: Colors.green,
                        )
                      : Image.network(
                          company['picture'] ?? 'https://via.placeholder.com/50',
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      isFreteGratis
                          ? 'Entrega Rápida' // Nome para o frete grátis
                          : '${utf8.decode(company['name'].toString().runes.toList())} - ${utf8.decode(frete['name'].toString().runes.toList())}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isFreteGratis
                      ? const Text(
                          'Frete grátis!',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      : Text(
                          'Preço: ${frete['currency']} ${frete['price']}',
                          style: const TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                    const SizedBox(height: 4),
                    Text(
                      isFreteGratis
                          ? 'Prazo de entrega: até 5 horas úteis' // Prazo de entrega para o frete grátis
                          : 'Prazo de Entrega: ${frete['delivery_time']} dias úteis',
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
}