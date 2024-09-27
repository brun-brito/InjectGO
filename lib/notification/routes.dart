import 'package:flutter/material.dart';
import 'package:inject_go/main.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';
import 'package:inject_go/subtelas/distribuidores/minhas_vendas.dart';
import 'package:inject_go/subtelas/profissionais/mercado/minhas_compras.dart';

class Routes {
  // Chave global para o controle de navegação
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Definição de todas as rotas em um único lugar
  static Map<String, Widget Function(BuildContext)> list = <String, WidgetBuilder>{
    '/home': (_) => const MyApp(),

    '/profile': (context) {
      // Verificando os argumentos passados para a rota 'profile'
      final email = ModalRoute.of(context)?.settings.arguments as String?;
      if (email != null) {
        return ProfileScreen(username: email);
      } else {
        return const Scaffold(
          body: Center(child: Text('Argumento "email" ausente para a tela de perfil.')),
        );
      }
    },

    '/profile_distribuidor': (context) {
      // Verificando os argumentos passados para a rota 'profile_distribuidor'
      final email = ModalRoute.of(context)?.settings.arguments as String?;
      if (email != null) {
        return ProfileScreenDistribuidor(username: email);
      } else {
        return const Scaffold(
          body: Center(child: Text('Argumento "email" ausente para o perfil do distribuidor.')),
        );
      }
    },

    '/minhas_vendas': (context) {
      // Verificando os argumentos passados para a rota 'minhas_vendas'
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('distribuidorId') && args.containsKey('email') && args.containsKey('initialTab')) {
        return MinhasVendasScreen(
          id: args['distribuidorId'] as String,
          email: args['email'] as String,
          initialTab: args['initialTab'] as int,
        );
      } else {
        return const Scaffold(
          body: Center(child: Text('Argumentos inválidos ou ausentes para Minhas Vendas.')),
        );
      }
    },

    '/minhas_compras': (context) {
      // Verificando os argumentos passados para a rota 'minhas_compras'
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('profissionalId') && args.containsKey('initialTab')) {
        return MinhasComprasScreen(
          userEmail: args['profissionalId'] as String,
          initialTab: args['initialTab'] as int,
        );
      } else {
        return const Scaffold(
          body: Center(child: Text('Argumentos inválidos ou ausentes para Minhas Compras.')),
        );
      }
    },

    // Adicione outras rotas aqui conforme necessário...
  };

  // Rota inicial padrão
  static const String initial = '/home';
}