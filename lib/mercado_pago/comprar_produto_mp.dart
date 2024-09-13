// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inject_go/subtelas/profissionais/minhas_compras.dart';

class ProductPurchaseScreen extends StatefulWidget {
  final String initPoint;
  final String productId;
  final String userEmail;
  final Map<String, String> endereco;  // Adicione o endereço como parâmetro

  const ProductPurchaseScreen({
    super.key, 
    required this.initPoint, 
    required this.productId, 
    required this.userEmail, 
    required this.endereco
  });

  @override
  _ProductPurchaseScreenState createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<ProductPurchaseScreen> {
  InAppWebViewController? webViewController;
  bool _isProcessing = false;  // Controla o estado de processamento

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra do Produto'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (webViewController != null) {
              bool canGoBack = await webViewController!.canGoBack();
              if (canGoBack) {
                webViewController!.goBack();  // Volta para a página anterior
              } else {
                Navigator.pop(context);  // Sai da tela caso não possa voltar
              }
            } else {
              Navigator.pop(context);  // Sai da tela caso não tenha controlador
            }
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(widget.initPoint)),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              if (url != null) {
                if (url.toString().contains("success") && url.toString().contains("payment_id")) {
                  final Uri uri = Uri.parse(url.toString());
                  String? paymentId = uri.queryParameters['payment_id'];

                  await _handlePaymentSuccess(paymentId);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MinhasComprasScreen(userEmail: widget.userEmail,)),
                  );

                } else if (url.toString().contains("failure")) {
                  _showError("O pagamento falhou. Tente novamente.");
                  Navigator.pop(context);
                } else if (!url.toString().contains("approved")) {
                    if (await webViewController!.canGoBack()) {
                      webViewController!.goBack();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Por favor, aguarde o tempo de processamento do pagamento.'),
                      ));
                    }
                }
              }
            },
            onLoadError: (controller, url, code, message) {
              _showError("Erro ao carregar o pagamento. Tente novamente.");
              Navigator.pop(context);
            },
          ),

          // Overlay de carregamento quando estiver processando
          if (_isProcessing) ...[
            AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 236, 63, 121),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Função para tratar pagamento com sucesso e salvar a compra no Firestore
  Future<void> _handlePaymentSuccess(String? paymentId) async {
    setState(() {
      _isProcessing = true;
    });

    final DateTime now = DateTime.now();

    // Buscar o produto comprado
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('id', isEqualTo: widget.productId)
        .limit(1)
        .get();

    if (productSnapshot.docs.isEmpty) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final productData = productSnapshot.docs.first.data() as Map<String, dynamic>;
    final String distributorId = productSnapshot.docs.first.reference.parent.parent!.id;

    // Buscar o comprador (profissional que fez a compra)
    QuerySnapshot buyerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userEmail)
        .limit(1)
        .get();

    if (buyerSnapshot.docs.isEmpty) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final buyerData = buyerSnapshot.docs.first.data() as Map<String, dynamic>;
    final String buyerId = buyerSnapshot.docs.first.id;

    // Criar mapa com os dados do comprador
    Map<String, dynamic> buyerInfo = {
      'nome': buyerData['nome'],
      'email': buyerData['email'],
      'telefone': buyerData['telefone'],
    };

    // Criar mapa com os dados do produto
    Map<String, dynamic> productInfo = {
      'productId': productData['id'],
      'nome': productData['name'],
      'preco': productData['price'],
      'marca': productData['marca'],
      'categoria': productData['categoria'],
      'imageUrl': productData['imageUrl'],
    };

    // Buscar dados do distribuidor
    DocumentSnapshot distributorSnapshot = await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distributorId)
        .get();

    if (!distributorSnapshot.exists) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Criar mapa com os dados do distribuidor
    Map<String, dynamic> distributorInfo = {
      'razao_social': distributorSnapshot['razao_social'],
      'cnpj': distributorSnapshot['cnpj'],
      'email': distributorSnapshot['email'],
      'telefone': distributorSnapshot['telefone'],
    };

    // Atualizar a coleção 'compras' do profissional com dados do distribuidor e payment_id
    DocumentReference compraRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(buyerId)
        .collection('compras')
        .add({
      'productInfo': productInfo,
      'distributorInfo': distributorInfo,  // Adiciona os dados do distribuidor
      'payment_id': paymentId,  // Adiciona o payment_id
      'data_compra': now,
      'status': 'solicitado',
      'endereco_entrega': widget.endereco, 
    });

    // Atualizar a coleção 'vendas' do distribuidor com dados do comprador e payment_id
    await FirebaseFirestore.instance
        .collection('distribuidores')
        .doc(distributorId)
        .collection('vendas')
        .add({
      'buyerInfo': buyerInfo,
      'productInfo': productInfo,
      'payment_id': paymentId,
      'data_pedido': now,
      'status': 'solicitado',
      'endereco_entrega': widget.endereco, 
      'compraId': compraRef.id, 
    });

    setState(() {
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}


/*
https://injectgo.com.br/product-success.html?collection_id=87781960842&
collection_status=approved&payment_id=87781960842&status=approved&
external_reference=null&payment_type=credit_card&merchant_order_id=22782573127&
preference_id=1983286839-755865aa-e28a-45a8-b5d4-e0ec0b9f353f&site_id=MLB&
processing_mode=aggregator&merchant_account_id=null

Pegar o payment_id no get https://api.mercadopago.com/v1/payments/{payment_id}
 
 
 https://www.mercadopago.com.br/checkout/v1/payment/redirect/4590eca1-0a32-402d-9468-f4a942430f80/congrats/approved/?preference-id=1983286839-755865aa-e28a-45a8-b5d4-e0ec0b9f353f&router-request-id=a4878c97-2cda-44a1-b9c0-4ea5f5be99dc&p=2d8c22bf6c2c11b34cd0769eab1949a6
 */