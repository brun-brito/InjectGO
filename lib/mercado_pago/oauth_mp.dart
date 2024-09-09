// ignore_for_file: prefer_const_constructors_in_immutables, library_private_types_in_public_api, use_key_in_widget_constructors, use_build_context_synchronously
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';

class MercadoPagoOAuthScreen extends StatefulWidget {
  final String username;
  final String userEmail;

  MercadoPagoOAuthScreen({required this.username, required this.userEmail});

  @override
  _MercadoPagoOAuthScreenState createState() => _MercadoPagoOAuthScreenState();
}

class _MercadoPagoOAuthScreenState extends State<MercadoPagoOAuthScreen> {
  InAppWebViewController? webViewController;
  final String clientId = dotenv.env['MERCADO_PAGO_CLIENT_ID'] ?? '';
  final String clientSecret = dotenv.env['MERCADO_PAGO_CLIENT_SECRET'] ?? '';
  final String redirectUri = "https://injectgo.com.br/success.html";
  String state = '';

  @override
  void initState() {
    super.initState();
    state = generateRandomState();
  }

  String generateRandomState() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Autenticação Mercado Pago")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse(
              "https://auth.mercadopago.com.br/authorization?client_id=$clientId&response_type=code&platform_id=mp&state=$state&redirect_uri=$redirectUri"),
//https://auth.mercadopago.com.br/authorization?client_id=99999999&response_type=code&platform_id=mp&state=TESTE123&redirect_uri=https://injectgo.com.br/success.html
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStop: (controller, url) async {
          if (url != null) {
            // Verificar se o redirecionamento contém 'success' e extrair o código
            if (url.toString().contains('success')) {
              Uri uri = Uri.parse(url.toString());
              String? authorizationCode = uri.queryParameters['code'];  // Extrai o código

              if (authorizationCode != null) {
                // Trocar o código pelo access token
                bool success = await _fetchAccessToken(authorizationCode);

                if (success) {
                  // Exibe uma mensagem de sucesso e retorna à tela de perfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conta vinculada com sucesso! Acesso liberado.'),
                    ),
                  );
                  Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreenDistribuidor(username: widget.userEmail),
                        ),
                      ); // Volta para a tela de perfil
                } else {
                  // Mostra um erro se a autenticação falhou
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao autenticar. Por favor, tente novamente.'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao processar a autorização. Tente novamente.'),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  // Função para trocar o código de autorização pelo access token e salvar as credenciais
  Future<bool> _fetchAccessToken(String code) async {

    try {
      final response = await http.post(
        Uri.parse('https://api.mercadopago.com/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String accessToken = data['access_token'].toString();
        final String refreshToken = data['refresh_token'].toString();
        final String userId = data['user_id'].toString();
        final String publicKey = data['public_key'].toString();


        // Salva as credenciais no Firestore
        await FirebaseFirestore.instance.collection('distribuidores').doc(widget.username).update({
          'credenciais_mp': {
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'user_id': userId,
            'public_key': publicKey,
          }
        });

        return true;  // Sucesso
      } else {
        return false;  // Falha na autenticação
      }
    } catch (e) {
      return false;  // Falha no processo de requisição
    }
  }
}
