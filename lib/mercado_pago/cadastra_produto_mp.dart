import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MercadoPagoService {
  final String marketplace;

  MercadoPagoService({required this.marketplace});

  Future<Map<String, dynamic>> criarPreferenciaProduto({
    required String productId,
    required String name,
    required String description,
    required String imageUrl,
    required String normalizedCategory,
    required double price,
    required String username,
    required String accessTokenVendedor,
  }) async {
    const url = 'https://api.mercadopago.com/checkout/preferences';
    final headers = {
      'Authorization': 'Bearer $accessTokenVendedor',
      'Content-Type': 'application/json',
    };

    // Cálculo da comissão de 5% sobre o valor do produto
    final String? taxaStr = dotenv.env['TAXA_MERCADO_PAGO'];
    final double? taxa = double.tryParse(taxaStr ?? '0');
    final double marketplaceFee = price * (taxa ?? 0.05);

    // Corpo da requisição JSON
    final body = jsonEncode({
      "items": [
        {
          "id": productId,
          "title": name,
          "description": description,
          "picture_url": imageUrl,
          "category_id": normalizedCategory,
          "quantity": 1,
          "currency_id": "BRL",
          "unit_price": price
        }
      ],
      "back_urls": {
        "success": "https://injectgo.com.br/product-success.html",
        "failure": "https://injectgo.com.br/product-failure.html",
      },
      "auto_return": "all",
      "marketplace": marketplace,
      "marketplace_fee": marketplaceFee
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        // Obter os dados relevantes da resposta
        final responseData = json.decode(response.body);
        final String initPoint = responseData['init_point'];
        final String preferenceId = responseData['id'];  // ID da preferência
        final String dateCreated = responseData['date_created'];  // Data de criação

        // Retornar os dados em um map para serem usados na criação do produto no Firestore
        return {
          'id': preferenceId,
          'init_point': initPoint,
          'date_created': dateCreated,
          'marketplace_fee': marketplaceFee,
        };
      } else {
        throw Exception('Erro ao criar preferência: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;  // Repassa o erro para o código que chamou este método
    }
  }
}