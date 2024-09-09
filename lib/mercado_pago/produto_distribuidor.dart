import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MercadoPagoService {
  final String marketplace;  // Access token do Marketplace

  MercadoPagoService({
    required this.marketplace,
  });

  Future<void> criarPreferenciaProduto({
    required String productId,
    required String name,
    required String description,
    required String imageUrl,
    required String normalizedCategory,
    required double price,
    required String username,
    required String accessTokenVendedor,  // Token do vendedor/distribuidor
  }) async {
    const url = 'https://api.mercadopago.com/checkout/preferences';
    final headers = {
      'Authorization': 'Bearer $accessTokenVendedor',  // Token do vendedor no Header
      'Content-Type': 'application/json',
    };

    // Cálculo da comissão de 5% sobre o valor do produto
    final double marketplaceFee = price * 0.05;

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
      "marketplace": marketplace,  // Access token do marketplace no Body
      "marketplace_fee": marketplaceFee
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        // Obter o init_point da resposta e outros dados relevantes
        final responseData = json.decode(response.body);
        final String initPoint = responseData['init_point'];
        final String preferenceId = responseData['id'];  // ID da preferência
        final String dateCreated = responseData['date_created'];  // Data de criação

        // Salvar os dados no Firebase no campo produto_mp
        await FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(username)
            .collection('produtos')
            .doc(productId)
            .update({
          'produto_mp': {
            'id': preferenceId,
            'init_point': initPoint,
            'date_created': dateCreated,
            'marketplace_fee': marketplaceFee,
          }
        });

        print("Preferência criada com sucesso e dados do Mercado Pago salvos no Firebase.");
      } else {
        throw Exception('Erro ao criar preferência: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao criar preferência: $e');
      rethrow;
    }
  }
}
