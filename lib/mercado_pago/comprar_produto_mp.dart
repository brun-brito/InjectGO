// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPurchaseScreen extends StatefulWidget {
  final String initPoint;
  final String productId;
  final String userEmail;  // Email do profissional (userId será o email)

  const ProductPurchaseScreen({super.key, required this.initPoint, required this.productId, required this.userEmail});

  @override
  _ProductPurchaseScreenState createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<ProductPurchaseScreen> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra do Produto'),
        centerTitle: true,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(widget.initPoint)),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
        },
        onLoadStop: (controller, url) async {

          // Verifica se a URL de sucesso ou falha foi carregada
          if (url != null && url.toString().contains("success")) {
            // Se a URL contém "success", trata o pagamento aprovado
            await _handlePaymentSuccess();

            // Exibir uma mensagem de sucesso
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Compra efetuada com sucesso!'),
            ));

            // Navegar de volta após a compra
            Navigator.pop(context);
          } else if (url != null && url.toString().contains("failure")) {
            // Se a URL contém "failure", trata o pagamento falho
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('O pagamento falhou. Por favor, tente novamente.'),
            ));

            // Navegar de volta após o erro
            Navigator.pop(context);
          }
        },
        onLoadError: (controller, url, code, message) {
        },
      ),
    );
  }

  // Função para tratar pagamento com sucesso e salvar a compra no Firestore
  Future<void> _handlePaymentSuccess() async {
    final DateTime now = DateTime.now();

    // Usar `collectionGroup` para buscar o produto independente da hierarquia do distribuidor
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collectionGroup('produtos')
        .where('id', isEqualTo: widget.productId) // Busca pelo productId
        .limit(1)
        .get();

    if (productSnapshot.docs.isEmpty)
      return;

    final productData = productSnapshot.docs.first.data() as Map<String, dynamic>;

    // Salvar a compra na coleção 'compras' dentro da coleção 'users'
    await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userEmail) // Buscar o usuário pelo email
        .limit(1)
        .get()
        .then((userSnapshot) {
      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;  // ID do documento do usuário

        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('compras')
            .add({
          'productId': widget.productId,
          'productName': productData['name'],
          'price': productData['price'],
          'purchaseDate': now,
          'status': 'approved',
          'paymentMethod': 'Mercado Pago',  // Método de pagamento
        });

      }
    });
  }
}
