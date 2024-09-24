import 'package:flutter/material.dart';
import 'package:inject_go/main.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';
import 'package:inject_go/subtelas/distribuidores/minhas_vendas.dart';

class Routes {
  static Map<String, Widget Function(BuildContext)> list = <String, WidgetBuilder>{
    '/home': (_) => const MyApp(),
    '/profile': (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String;
      return ProfileScreen(username: email);
    },
    '/profile_distribuidor': (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String;
      return ProfileScreenDistribuidor(username: email);
    },
    '/minhas_vendas': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      final distribuidorId = args['distribuidorId'] as String;
      final initialTab = args['initialTab'] as int;
      return MinhasVendasScreen(id: distribuidorId, initialTab: initialTab);
    },
  };

  static String initial = '/home';
  static GlobalKey<NavigatorState>? navigatorKey = GlobalKey<NavigatorState>();
}
