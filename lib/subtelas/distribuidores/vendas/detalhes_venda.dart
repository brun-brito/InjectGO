// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/formatadores/formata_texto_negrito.dart';
import 'package:uuid/uuid.dart';
// TODO: URL PRA TESTAR LOCAL: http://192.168.15.60:3000
// TODO: COLOCAR OS PRAZOS DE ENTREGA
// TODO: Colocar o botão de envuar com formulário de código de rastreio etc *ver como funciona
class DetalhesVendaScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> vendasDoPedido;
  final String paymentId;
  final String pedidoId;
  final String distribuidorId;

  const DetalhesVendaScreen({
    super.key,
    required this.vendasDoPedido,
    required this.paymentId,
    required this.pedidoId,
    required this.distribuidorId,
  });

  @override
  _DetalhesVendaScreenState createState() => _DetalhesVendaScreenState();
}

class _DetalhesVendaScreenState extends State<DetalhesVendaScreen> {
  late Future<Map<String, dynamic>> _paymentDetailsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentDetailsFuture = fetchPaymentDetails(widget.paymentId, widget.distribuidorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Pedido'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
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
              final valorProdutos = pagamento['transaction_details']['total_paid_amount'];
              final valorFrete = pagamento['shipping_amount'];
              final valorTotal = pagamento['transaction_amount'];
              final compradorEmail = widget.vendasDoPedido[0]['buyerInfo']['email'];
              final itens = pagamento['additional_info']['items'];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exibe informações sobre o pagamento
                    buildRichTextColor('Status do Pagamento: ', _mapPaymentStatus(status), _getStatusColor(status)),
                    buildRichTextColor('Total produtos: ', 'R\$ $valorProdutos'),
                    buildRichTextColor('Frete: ', 'R\$ $valorFrete'),
                    buildRichTextColor('Valor Total Pago: ', 'R\$ $valorTotal'),
                    buildRichTextColor('Comprador: ', compradorEmail),

                    // Exibe os itens comprados
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
                              leading: imagem != null && imagem.isNotEmpty
                                  ? Image.network(imagem, width: 50, height: 50)
                                  : const Icon(Icons.shopping_bag, size: 50),
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

                    // Botões de Aprovar e Rejeitar
                    if (widget.vendasDoPedido.first['status'] == 'solicitado') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _aprovarVenda(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Aprovar', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : () async => _rejeitarVenda(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Rejeitar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ]
                    else if (widget.vendasDoPedido.first['status'] == 'preparando') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _enviarPedido(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Postar pedido', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                    // Exibe informações de contato
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchCompradorInfo(compradorEmail),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erro ao carregar informações do comprador: ${snapshot.error}'));
                        } else if (!snapshot.hasData) {
                          return const Center(child: Text('Informações do comprador não disponíveis.'));
                        }

                        final compradorInfo = snapshot.data!;
                        final compradorTelefone = compradorInfo['telefone'];
                        final compradorEmail = widget.vendasDoPedido[0]['buyerInfo']['email'];

                        return Container(
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
                              _buildContactInfo(context, 'Telefone do comprador: ', compradorTelefone),
                              _buildContactInfo(context, 'Email do comprador: ', compradorEmail),
                              _buildContactInfo(context, 'Suporte InjectGO: ', 'suporte@injectgo.com.br'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Carregamento durante o processamento
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121))),
            ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCompradorInfo(String compradorEmail) async {
    final compradorSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: compradorEmail)
        .limit(1)
        .get();
      
    if (compradorSnapshot.docs.isEmpty) {
      throw Exception('Comprador não encontrado com o email: $compradorEmail');
    }

    final compradorData = compradorSnapshot.docs.first.data();
    return {
      'telefone': compradorData['telefone'] ?? 'Telefone não disponível',
      'email': compradorData['email'] ?? 'Email não disponível',
    };
  }

  // Exibe as informações de contato
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
    
  Future<void> _enviarNotificacaoComprador(String buyerEmail, String titulo, String mensagem) async {
    try {
      // Obter o documento do comprador (profissional) no Firestore
      final buyerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: buyerEmail)
          .limit(1)
          .get();

      if (buyerSnapshot.docs.isEmpty) {
        debugPrint('Comprador não encontrado com o email: $buyerEmail');
        return;
      }

      final buyerData = buyerSnapshot.docs.first.data();

      // Obter a lista de tokens (contendo tanto FCM quanto APNS)
      final List<dynamic> tokens = buyerData['tokens'] ?? [];

      if (tokens.isEmpty) {
        debugPrint('Nenhum token FCM/APNS encontrado para o comprador $buyerEmail.');
        return;
      }
        // Prepara os dados para o payload da notificação
        final payload = {
          "email": buyerEmail,
          "titulo": titulo,
          "mensagem": mensagem
        };

        final url = '${dotenv.env['ENDERECO_SERVIDOR']}/enviar-notificacao-profissional';

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          debugPrint('Notificação enviada com sucesso para $buyerEmail');
        } else {
          debugPrint('Erro ao enviar notificação para $buyerEmail: ${response.body}');
        }
    } catch (error) {
      debugPrint('Erro ao enviar notificação para o comprador: $error');
    }
  }

  Future<void> enviarEmailProfissional(String externalReference, String profissionalId, String status) async {
    final url = Uri.parse('${dotenv.env['ENDERECO_SERVIDOR']}/enviar-email-profissional');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "externalReference": externalReference,
        "profissionalId": profissionalId,
        "status": status,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('E-mail enviado com sucesso');
    } else {
      debugPrint('Falha ao enviar o e-mail: ${response.body}');
    }
  }

  // Função para aprovar o pedido
  void _aprovarVenda(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['ENDERECO_SERVIDOR']}/aprovar-pedido'),
        // Uri.parse('http://192.168.15.60:3000/aprovar-pedido'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'distribuidorId': widget.distribuidorId,
          'pedidoId': widget.pedidoId,
        }),
      );

      // Verifica se a resposta foi bem-sucedida
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido aprovado com sucesso!')),
        );
        Navigator.pop(context); // Volta para a tela de listagem após aprovação
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aprovar o pedido: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar o pedido: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para rejeitar o pedido
  void _rejeitarVenda(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reembolsoData = await _realizarReembolso(widget.paymentId, widget.distribuidorId);

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
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: buyerEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String buyerId = querySnapshot.docs.first.id;
          String compraId = venda.id;

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

          await _enviarNotificacaoComprador(buyerEmail, 'Compra rejeitada', 'Sua compra foi rejeitada e reembolsada.');
          await enviarEmailProfissional(compraId, buyerId, 'rejeitado');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido rejeitado e reembolso realizado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar pedido: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //TODO: Implementar enviar pedido com endpoint real
  void _enviarPedido(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['ENDERECO_SERVIDOR']}/enviar-pedido'),
        // Uri.parse('http://192.168.15.60:3000/enviar-pedido'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'distribuidorId': widget.distribuidorId,
          'pedidoId': widget.pedidoId,
        }),
      );

      // Verifica se a resposta foi bem-sucedida
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido enviado com sucesso!')),
        );
        Navigator.pop(context); // Volta para a tela de listagem após aprovação
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar pedido: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pedido: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para realizar o reembolso via Mercado Pago
  Future<Map<String, dynamic>> _realizarReembolso(String paymentId, String distribuidorId) async {
    try {
      // Gera a chave de idempotência (UUID V4)
      var uuid = const Uuid();
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
        throw Exception('Erro ao realizar o reembolso. Não será possível recusar a compra agora.');
      }
    } catch (e) {
      throw Exception('Erro ao realizar o reembolso. Não será possível recusar a compra agora.');
    }
  }

}