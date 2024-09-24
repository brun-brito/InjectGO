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

      // Verifique se o documento existe e se o campo credenciais_mp está presente
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (data.containsKey('credenciais_mp') && data['credenciais_mp'] is Map<String, dynamic>) {
          final credenciaisMp = data['credenciais_mp'] as Map<String, dynamic>;

          if (credenciaisMp.containsKey('access_token')) {
            String accessToken = credenciaisMp['access_token'];

            // Realiza a requisição ao Mercado Pago com o token
            final url = 'https://api.mercadopago.com/v1/payments/$paymentId';
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $accessToken',
              },
            );

            if (response.statusCode == 200) {
              return jsonDecode(response.body) as Map<String, dynamic>;
            } else {
              throw Exception('Erro ao buscar os detalhes de pagamento. Status: ${response.statusCode}');
            }
          } else {
            throw Exception('Access token não encontrado em credenciais_mp.');
          }
        } else {
          throw Exception('Campo credenciais_mp não encontrado ou mal formatado.');
        }
      } else {
        throw Exception('Documento do distribuidor não encontrado.');
      }
    } catch (e) {
      throw Exception('Erro ao buscar os detalhes de pagamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiraCompra = comprasDoPedido.first;

    // Faça o cast do data() para Map<String, dynamic>
    final Map<String, dynamic> compraData = primeiraCompra.data() as Map<String, dynamic>;

    // Verifique se o campo 'distributorInfo' existe
    final distributorInfo = compraData.containsKey('distributorInfo')
        ? compraData['distributorInfo'] as Map<String, dynamic>
        : null; // Defina como null se o campo não existir

    // Agora, ao exibir as informações, verifique se 'distributorInfo' não é nulo
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Compra'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPaymentDetails(paymentId, distributorInfo != null
            ? '${distributorInfo['razao_social']} - ${distributorInfo['cnpj']}'
            : 'Distribuidor Desconhecido'),
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
                      if (distributorInfo != null) ...[
                        _buildRichText('Status do Pagamento: ', _translatePaymentStatus(paymentDetails['status']),
                            _getStatusColor(paymentDetails['status'])),
                        const SizedBox(height: 10),
                        _buildRichText('Método de Pagamento: ', paymentDetails['payment_type_id']),
                        _buildRichText('Total Pago: ', 'R\$${paymentDetails['transaction_amount'].toStringAsFixed(2)}'),
                        _buildRichText('E-mail do pagador: ', paymentDetails['payer']['email']),
                        _buildRichText('Data de criação: ', formatDataHora(paymentDetails['date_created'])),
                        _buildRichText('Última atualização: ', formatDataHora(paymentDetails['date_last_updated'])),
                      ] else ...[
                          const Text('Informações do distribuidor indisponíveis.'),
                        ],
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
                              Text('Distribuidor: ${distributorInfo?['razao_social'] ?? 'Desconhecido'}'),
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
                        _buildContactInfo(context, 'Telefone do distribuidor: ', distributorInfo?['telefone']),
                        _buildContactInfo(context, 'Email do distribuidor: ', distributorInfo?['email']),
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
