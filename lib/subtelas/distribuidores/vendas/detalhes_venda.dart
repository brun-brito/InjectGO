import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class DetalhesVendaScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> vendasDoPedido;
  final String paymentId;
  final String distribuidorId;

  const DetalhesVendaScreen({
    super.key,
    required this.vendasDoPedido,
    required this.paymentId,
    required this.distribuidorId,
  });

  @override
  _DetalhesVendaScreenState createState() => _DetalhesVendaScreenState();
}

class _DetalhesVendaScreenState extends State<DetalhesVendaScreen> {
  late Future<Map<String, dynamic>> _paymentDetailsFuture;

  @override
  void initState() {
    super.initState();
    _paymentDetailsFuture = fetchPaymentDetails(widget.paymentId, widget.distribuidorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido: ${widget.paymentId}'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _paymentDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado disponível'));
          }

          final pagamento = snapshot.data!;
          final status = pagamento['status'];
          final descricao = pagamento['description'];
          final valorTotal = pagamento['transaction_amount'];
          final compradorEmail = pagamento['payer']['email'];
          final itens = pagamento['additional_info']['items'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status do Pagamento: ${_mapPaymentStatus(status)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Descrição: $descricao', style: const TextStyle(fontSize: 16)),
                Text('Valor Total Pago: R\$ $valorTotal', style: const TextStyle(fontSize: 16)),
                Text('Comprador: $compradorEmail', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text('Itens Comprados:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      final nomeProduto = item['title'];
                      final precoProduto = item['unit_price'];
                      final quantidade = item['quantity'];
                      final imagem = item['picture_url'];

                      return Card(
                        child: ListTile(
                          leading: Image.network(imagem, width: 50, height: 50),
                          title: Text(nomeProduto),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preço: R\$ $precoProduto'),
                              Text('Quantidade: $quantidade'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.vendasDoPedido.first['status'] == 'solicitado') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _aprovarVenda(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Aprovar', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _rejeitarVenda(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Rejeitar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  String _mapPaymentStatus(String status) {
    switch (status) {
      case 'refunded':
        return 'Reembolsado';
      case 'approved':
        return 'Aprovado';
      case 'in_process':
        return 'Em Processamento';
      case 'rejected':
        return 'Rejeitado';
      case 'pending':
        return 'Pendente';
      default:
        return 'Status Desconhecido';
    }
  }

  Future<Map<String, dynamic>> fetchPaymentDetails(String paymentId, String distribuidorId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distribuidorId)
        .get();

    if (!snapshot.exists || !snapshot.data().toString().contains('credenciais_mp')) {
      throw Exception('Access token não encontrado');
    }

    String accessToken = snapshot['credenciais_mp']['access_token'];

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
      throw Exception('Erro ao buscar os detalhes de pagamento');
    }
  }
    
  // Função para aprovar a venda
  void _aprovarVenda(BuildContext context) async {
    try {
      // TODO: Adicionar notificação para o comprador, que a compra foi aprovada e está em processo de preparo
      for (var venda in widget.vendasDoPedido) {
        String vendaId = venda.id;
        String buyerEmail = venda['buyerInfo']['email'];

        // Atualiza o status para o distribuidor
        await FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(widget.distribuidorId)
            .collection('vendas')
            .doc(vendaId)
            .update({'status': 'preparando'});

        // Atualiza o status para o comprador
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: buyerEmail)
            .limit(1)
            .get()
            .then((querySnapshot) async {
          if (querySnapshot.docs.isNotEmpty) {
            String buyerId = querySnapshot.docs.first.id;
            String compraId = venda['compraId'];

            await FirebaseFirestore.instance
                .collection('users')
                .doc(buyerId)
                .collection('compras')
                .doc(compraId)
                .update({
              'status': 'preparando',
            });
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda aprovada com sucesso!')),
      );
      Navigator.pop(context); // Volta para a tela de listagem após aprovação
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar a venda: $e')),
      );
    }
  }

  // Função para rejeitar a venda
  void _rejeitarVenda(BuildContext context) async {
    try {
      // TODO: Adicionar notificação para o comprador, que a compra foi reprovada e reembolsada
      final reembolsoData = await _realizarReembolso(widget.paymentId, widget.distribuidorId);

      // Se o reembolso for bem-sucedido, atualiza as informações no Firestore
      for (var venda in widget.vendasDoPedido) {
        String vendaId = venda.id;
        String buyerEmail = venda['buyerInfo']['email'];

        // Atualiza o status para o distribuidor e salva os dados do reembolso
        await FirebaseFirestore.instance
            .collection('distribuidores')
            .doc(widget.distribuidorId)
            .collection('vendas')
            .doc(vendaId)
            .update({
          'status': 'rejeitado',
          'reembolsoInfo': {
            'refund_id': reembolsoData['id'],
            'date_created': reembolsoData['date_created'],
            'status': reembolsoData['status'],
          },
        });

        // Atualiza o status para o comprador
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: buyerEmail)
            .limit(1)
            .get()
            .then((querySnapshot) async {
          if (querySnapshot.docs.isNotEmpty) {
            String buyerId = querySnapshot.docs.first.id;
            String compraId = venda['compraId'];

            await FirebaseFirestore.instance
                .collection('users')
                .doc(buyerId)
                .collection('compras')
                .doc(compraId)
                .update({
              'status': 'rejeitado',
              'reembolsoInfo': {
                'refund_id': reembolsoData['id'],
                'date_created': reembolsoData['date_created'],
                'status': reembolsoData['status'],
              },
            });
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda rejeitada e reembolso realizado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar a venda: $e')),
      );
    }
  }

  // Função para realizar o reembolso via Mercado Pago
  Future<Map<String, dynamic>> _realizarReembolso(String paymentId, String distribuidorId) async {
    try {
      // Gera a chave de idempotência (UUID V4)
      var uuid = Uuid();
      String idempotencyKey = uuid.v4();

      // Busca o access token no Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(distribuidorId)
          .get();

      if (!snapshot.exists || !snapshot.data().toString().contains('credenciais_mp')) {
        throw Exception('Access token não encontrado');
      }

      String accessToken = snapshot['credenciais_mp']['access_token'];

      // Faz a requisição de reembolso para o Mercado Pago
      final url = 'https://api.mercadopago.com/v1/payments/$paymentId/refunds';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-Idempotency-Key': idempotencyKey,  // Chave de idempotência gerada
        },
        body: jsonEncode({}),  // Envia o corpo vazio para solicitar o reembolso completo
      );

      if (response.statusCode == 201) {
        // Reembolso bem-sucedido
        Map<String, dynamic> refundData = jsonDecode(response.body);
        return {
          'id': refundData['id'],
          'date_created': refundData['date_created'],
          'status': refundData['status'],
        };
      } else {
        // Caso ocorra algum erro durante o reembolso
        throw Exception('Erro ao realizar o reembolso: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao realizar o reembolso: $e');
    }
  }

}