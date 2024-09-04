import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';

class SubscriptionScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  SubscriptionScreen({required this.userId, required this.userEmail});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final String planId = '2c93808491b45c770191b85b34d90162';
  final String accessToken = 'APP_USR-1709159904607332-072416-43222ee5707268796c8829b5f03d1dae-1914238007';
  InAppWebViewController? webViewController;

  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura do Plano'),
      ),
      body: Stack(
        children: [
          if (!_paymentCompleted) // Exibe o WebView apenas se o pagamento não foi concluído
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse(
                    'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=$planId'),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                });

                if (url != null && url.toString().contains('congrats')) {
                  // Faça a requisição para obter o último pagamento aprovado
                  await _verificarUltimoPagamento();

                  setState(() {
                    _paymentCompleted = true;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pagamento aprovado! Acesso liberado.'),
                  ));
                }
              },
              onLoadError: (controller, url, code, message) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao carregar a página: $message'),
                  ),
                );
              },
              onLoadHttpError: (controller, url, statusCode, description) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro HTTP: $statusCode $description'),
                  ),
                );
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'Pagamento aprovado! Acesso aos recursos liberado. Clique no botão abaixo para acessá-los!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreenDistribuidor(username: widget.userEmail),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 236, 63, 121), // Cor de fundo
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding do botão
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Bordas arredondadas
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16, // Tamanho da fonte
                        fontWeight: FontWeight.bold, // Peso da fonte
                      ),
                    ),
                    child: const Text(
                      'Acessar Recursos',
                      style: TextStyle(color: Colors.white), // Cor do texto
                    ),
                  )
                ],
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)))
        ],
      ),
    );
  }

  Future<void> _verificarUltimoPagamento() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.mercadopago.com/preapproval/search?preapproval_plan_id=$planId&status=authorized'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        if (results.isNotEmpty) {
          final lastTransaction = results.last; // Última transação aprovada
          final String transactionId = lastTransaction['id'];

          // Obtenha detalhes da transação usando o transactionId
          await _liberarAcesso(widget.userId, transactionId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Nenhuma transação aprovada encontrada.'),
          ));
        }
      } else {
        throw Exception('Erro ao buscar transações: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao verificar pagamento: $e'),
      ));
    }
  }

  Future<void> _liberarAcesso(String userId, String transactionId) async {
    // Faça uma nova requisição para obter detalhes específicos do pagamento
    final response = await http.get(
      Uri.parse('https://api.mercadopago.com/preapproval/$transactionId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final transactionDetails = json.decode(response.body);

      // Atualize o campo 'pagamento_em_dia' no Firestore
      await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(userId)
          .update({
        'pagamento_em_dia': true,
        'subscription_id': transactionDetails['subscription_id'],
        'payer_id': transactionDetails['payer_id'].toString(),
        'payer_email': transactionDetails['payer_email'],
      });

      print('Acesso liberado para o distribuidor: $userId');
    } else {
      throw Exception('Erro ao obter detalhes do pagamento: ${response.body}');
    }
  }
}
