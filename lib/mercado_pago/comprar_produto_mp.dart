// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/subtelas/profissionais/mercado/main_screen.dart';
import 'dart:async';

class ProductPurchaseScreen extends StatefulWidget {
  final String initPoint;
  final List<String> productIds;
  final String userEmail;
  final Map<String, String> endereco;
  final Position posicao;
  final String orderId;
  final Map<String, dynamic> envio;

  const ProductPurchaseScreen({
    super.key,
    required this.initPoint,
    required this.productIds,
    required this.userEmail,
    required this.endereco,
    required this.posicao,
    required this.orderId,
    required this.envio,
  });

  @override
  _ProductPurchaseScreenState createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<ProductPurchaseScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _openPaymentPage();
  }

  // Abre a URL do Mercado Pago no navegador interno
  Future<void> _openPaymentPage() async {
    FlutterWebBrowser.openWebPage(
      url: widget.initPoint,
      customTabsOptions: const CustomTabsOptions(
        showTitle: true,
      ),
      safariVCOptions: const SafariViewControllerOptions(
        barCollapsingEnabled: true,
        preferredBarTintColor: Colors.pink,
        preferredControlTintColor: Colors.white,
      ),
    );

    // Simula a checagem do status do pagamento após alguns segundos
    Future.delayed(const Duration(seconds: 10), () {
      _checkPaymentStatus();
    });
  }

  // Função para capturar o retorno da URL e verificar o `payment_id`
  Future<void> _checkPaymentStatus() async {

    await _handlePaymentSuccess();
    // Redireciona para a tela principal após o sucesso
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userPosition: widget.posicao,
          email: widget.userEmail,
          initialIndex: 3,
        ),
      ),
    );
  }

  // Função para processar o pagamento bem-sucedido e salvar no Firestore
  Future<void> _handlePaymentSuccess() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final DateTime now = DateTime.now();

      QuerySnapshot buyerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (buyerSnapshot.docs.isEmpty) {
        _showError("Erro ao obter dados do comprador.");
        return;
      }

      final buyerData = buyerSnapshot.docs.first.data() as Map<String, dynamic>;
      final String buyerId = buyerSnapshot.docs.first.id;

      Map<String, dynamic> buyerInfo = {
        'nome': buyerData['nome'],
        'email': buyerData['email'],
        'telefone': buyerData['telefone'],
      };

      // Inicializamos uma lista para armazenar as informações dos produtos
      List<Map<String, dynamic>> produtosCompra = [];
      List<Map<String, dynamic>> produtosVenda = [];
      String? distribuidorId;

      for (String productId in widget.productIds) {
        QuerySnapshot productSnapshot = await FirebaseFirestore.instance
            .collectionGroup('produtos')
            .where('id', isEqualTo: productId)
            .get();

        if (productSnapshot.docs.isNotEmpty) {
          DocumentSnapshot productDoc = productSnapshot.docs.first;
          // TODO: Alterar essa quantidade so quando o pagamento tiver confirmado
          int quantidadeAtual = productDoc['quantidade_disponivel'];
          if (quantidadeAtual > 0) {
            int novaQuantidade = quantidadeAtual - 1;

            // Atualizar a quantidade no banco de dados
            await productDoc.reference.update({
              'quantidade_disponivel': novaQuantidade,
              'disponivel': novaQuantidade > 0,
            });
          }

          Map<String, dynamic> productInfo = {
            'productId': productId,
            'nome': productDoc['name'],
            'preco': productDoc['price'],
            'marca': productDoc['marca'],
            'categoria': productDoc['categoria'],
            'imageUrl': productDoc['imageUrl'],
          };

          // Buscar dados do distribuidor
          distribuidorId = productDoc.reference.parent.parent!.id;
          DocumentSnapshot distributorSnapshot = await FirebaseFirestore.instance
              .collection('distribuidores')
              .doc(distribuidorId)
              .get();

          if (!distributorSnapshot.exists) continue;

          Map<String, dynamic> distributorInfo = {
            'razao_social': distributorSnapshot['razao_social'],
            'cnpj': distributorSnapshot['cnpj'],
            'email': distributorSnapshot['email'],
            'telefone': distributorSnapshot['telefone'],
          };

          // Adiciona as informações do produto à lista de produtos de compra e venda
          produtosCompra.add({
            'productInfo': productInfo,
            'distributorInfo': distributorInfo,
          });

          produtosVenda.add({
            'productInfo': productInfo,
            'buyerInfo': buyerInfo,
          });
        }
      }

      // Criar um único documento de compra/venda para o distribuidor e o usuário
      await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distribuidorId)
        .collection('vendas')
        .doc(widget.orderId)
        .set({
      'produtos': produtosVenda,
      'payment_id': '',
      'data_criacao': now,
      'status': 'pendente',
      'endereco_entrega': widget.endereco,
      'info_envio': widget.envio,
      });

      await FirebaseFirestore.instance
        .collection('users')
        .doc(buyerId)
        .collection('compras')
        .doc(widget.orderId)  // Usa o mesmo orderId
        .set({
      'produtos': produtosCompra,
      'payment_id': '',
      'data_criacao': now,
      'status': 'pendente',
      'endereco_entrega': widget.endereco,
      'info_entrega': widget.envio,
      });

      // Continua o fluxo da aplicação após salvar no banco
      setState(() {
        _isProcessing = false;
      });
    } catch (e, stacktrace) {
      debugPrint('Erro durante o processamento: $e');
      debugPrint(stacktrace.toString());
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Função para exibir erros
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processando Compra'),
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : const Text("Processando pagamento, por favor, aguarde..."),
      ),
    );
  }
}
