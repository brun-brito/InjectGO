import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:inject_go/formatadores/formata_data.dart';
import 'package:flutter/services.dart'; // Para copiar textos

class DetalhesCompraScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> comprasDoPedido;
  final String paymentId;
  final String userEmail;

  const DetalhesCompraScreen({
    super.key,
    required this.comprasDoPedido,
    required this.paymentId,
    required this.userEmail,
  });

  Future<Map<String, dynamic>> fetchPaymentDetails(String paymentId, String distribuidorId) async {
    try {
      // Busca o access token na coleção distribuidores
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(distribuidorId)
          .get();

      if (!snapshot.exists || !snapshot.data().toString().contains('credenciais_mp')) {
        throw Exception('Access token não encontrado');
      }

      // String accessToken = snapshot['credenciais_mp']['access_token'];

      final url = 'https://api.mercadopago.com/v1/payments/$paymentId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer APP_USR-1654544103970422-092308-b9c10e3876cee80cc85d7ba771696cdb-276779058',//$accestoken
          //APP_USR-1654544103970422-092308-b9c10e3876cee80cc85d7ba771696cdb-276779058
          //APP_USR-3686677339330781-091612-5cfe9d75683d284b0544ba8cb449d713-1994695758
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao buscar os detalhes de pagamento');
      }
    } catch (e) {
      throw Exception('Erro ao buscar os detalhes de pagamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiraCompra = comprasDoPedido.first;
    final distributorInfo = primeiraCompra['distributorInfo'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Compra'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPaymentDetails(paymentId, '${distributorInfo['razao_social']} - ${distributorInfo['cnpj']}'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar detalhes do pagamento: ${snapshot.error}'),
            );
          }

          final paymentDetails = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRichText('Status do Pagamento: ', _translatePaymentStatus(paymentDetails['status']),
                            _getStatusColor(paymentDetails['status'])),
                        const SizedBox(height: 10),
                        _buildRichText('Método de Pagamento: ', paymentDetails['payment_type_id']),
                        _buildRichText('Total Pago: ', 'R\$${paymentDetails['transaction_amount'].toStringAsFixed(2)}'),
                        _buildRichText('E-mail do pagador: ', paymentDetails['payer']['email']),
                        _buildRichText('Data de compra: ', formatDataHora(paymentDetails['date_created'])),
                        _buildRichText('Última atualização: ', formatDataHora(paymentDetails['date_last_updated'])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Produtos:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comprasDoPedido.length,
                    itemBuilder: (context, index) {
                      final compra = comprasDoPedido[index].data() as Map<String, dynamic>;
                      final productInfo = compra['productInfo'] as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: productInfo['imageUrl'] != null
                                ? Image.network(
                                    productInfo['imageUrl'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported, size: 60),
                          ),
                          title: Text(
                            productInfo['nome'] ?? 'Produto sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text('Preço: R\$ ${productInfo['preco']?.toStringAsFixed(2) ?? 'N/A'}'),
                              Text('Quantidade: ${productInfo['quantidade'] ?? 1}'),
                              Text('Distribuidor: ${distributorInfo['razao_social'] ?? 'Desconhecido'}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entre em contato:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.pinkAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildContactInfo(context, 'Telefone do distribuidor: ', distributorInfo['telefone']),
                        _buildContactInfo(context, 'Email do distribuidor: ', distributorInfo['email']),
                        _buildContactInfo(context, 'Suporte InjectGO: ', 'suporte@injectgo.com.br'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRichText(String title, String value, [Color? color]) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontSize: 16, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, String title, String contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            TextSpan(
              text: contact,
              style: const TextStyle(color: Colors.blue, fontSize: 16),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Clipboard.setData(ClipboardData(text: contact));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informação copiada!')),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  String _translatePaymentStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      case 'refunded':
        return 'Reembolsado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.black87;
    }
  }
}