// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductMpScreen {
  final String mpProductId;
  final String productId;
  final String updatedName;
  final String updatedDescription;
  final String updatedImageUrl;
  final String updatedNormalizedCategory;
  final double updatedPrice;
  final double updatedMarketplaceFee;
  final String distributorAccessToken; // Token do distribuidor obtido do Firestore
  final String? marketplace; // Marketplace token

  EditProductMpScreen({
    required this.mpProductId,
    required this.productId,
    required this.updatedName,
    required this.updatedDescription,
    required this.updatedImageUrl,
    required this.updatedNormalizedCategory,
    required this.updatedPrice,
    required this.updatedMarketplaceFee,
    required this.distributorAccessToken,
    required this.marketplace,
  });

  Future<bool> editProductInMp() async {
    try {
      // Corpo da requisição PUT
      final body = jsonEncode({
        "items": [
          {
            "id": productId,
            "title": updatedName,
            "description": updatedDescription,
            "picture_url": updatedImageUrl,
            "category_id": updatedNormalizedCategory,
            "quantity": 1,
            "currency_id": "BRL",
            "unit_price": updatedPrice
          }
        ],
        "back_urls": {
          "success": "https://injectgo.com.br/product-success.html",
          "failure": "https://injectgo.com.br/product-failure.html",
        },
        "auto_return": "all",
        "marketplace": marketplace,
        "marketplace_fee": updatedMarketplaceFee
      });

      // Requisição PUT no Mercado Pago
      final response = await http.put(
        Uri.parse('https://api.mercadopago.com/checkout/preferences/$mpProductId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $distributorAccessToken',
        },
        body: body,
      );

      // Verificar se a resposta foi bem-sucedida
      if (response.statusCode == 200) {
        return true;
      } else {
        return false; 
      }
    } catch (e) {
      return false;
    }
  }
}
