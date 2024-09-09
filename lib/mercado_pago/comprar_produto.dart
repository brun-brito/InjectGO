// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ProductPurchaseScreen extends StatefulWidget {
  final String initPoint;

  const ProductPurchaseScreen({super.key, required this.initPoint});

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
          print('Página sendo carregada: $url');
        },
        onLoadStop: (controller, url) {
          print('Página carregada: $url');
        },
        onLoadError: (controller, url, code, message) {
          print('Erro ao carregar a página: $message');
        },
      ),
    );
  }
}
