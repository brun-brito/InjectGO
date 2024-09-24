import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MercadoPagoService {
  MercadoPagoService();

  Future<Map<String, dynamic>> criarPreferenciaCarrinho({
    required List<Map<String, dynamic>> cartProducts,
    required String accessTokenVendedor,
    required String distribuidorId,
    required String profissionalId,
  }) async {
    const String serverUrl = 'https://verifica-pagamento-mp-production.up.railway.app';
    const url = 'https://api.mercadopago.com/checkout/preferences';
    final headers = {
      'Authorization': 'Bearer $accessTokenVendedor',
      'Content-Type': 'application/json',
    };

    // Gera um UUID para representar o pedido único
    var uuid = const Uuid();
    String orderId = uuid.v4();

    // External reference será o ID do pedido, que será usado no backend para vincular a compra
    String externalReference = orderId;

    // Cálculo da comissão de 5% sobre o valor de cada produto
    final String? taxaStr = dotenv.env['TAXA_MERCADO_PAGO'];
    final double? taxa = double.tryParse(taxaStr ?? '0');
    final String marketplace = dotenv.env['MERCADO_PAGO_ACCESS_TOKEN'] ?? '';
    double totalMarketplaceFee = 0;

    // Criar a lista de itens para a preferência no formato do Mercado Pago
    final List<Map<String, dynamic>> items = cartProducts.map((product) {
      double price = (product['price'] as num).toDouble();      
      final int quantity = product['quantity'] as int;

      // Calcular a comissão sobre o valor do produto
      final double marketplaceFee = double.parse((price * taxa!).toStringAsFixed(2));
      totalMarketplaceFee += marketplaceFee * quantity;

      return {
        "id": product['productId'],
        "title": product['name'],
        "description": product['description'],
        "picture_url": product['imageUrl'],
        "category_id": product['category'],
        "quantity": quantity,
        "currency_id": "BRL",
        "unit_price": price,
      };
    }).toList();

    // Corpo da requisição JSON
    final body = jsonEncode({
      "items": items,
      "back_urls": {
        "success": '$serverUrl/success',
        "failure": '$serverUrl/failure',
      },
      "payment_methods": {
        "excluded_payment_types": [
          {"id": "ticket"},
        ],
        "default_payment_method_id": "account_money",
        "installments": 5,
        "default_installments": 1
      },
      "auto_return": "approved",
      "external_reference": externalReference,
      "marketplace": marketplace,
      "marketplace_fee": totalMarketplaceFee,
      // "shipments":{ TODO: Pra colocar o preço do envio
      //   "cost": 1000,
      //   "mode": "not_specified",
      // }
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
        final String preferenceId = responseData['id'];
        final String dateCreated = responseData['date_created'];

        // Retornar os dados em um map para serem usados na criação do produto no Firestore
        return {
          'id': preferenceId,
          'init_point': initPoint,
          'date_created': dateCreated,
          'marketplace_fee': totalMarketplaceFee,
          'order_id': orderId,
        };
      } else {
        throw Exception('Erro ao criar preferência: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;  // Repassa o erro para o código que chamou este método
    }
  }
}