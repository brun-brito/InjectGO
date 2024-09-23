import 'package:flutter/material.dart';
import 'package:inject_go/main.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/screens/profile_screen_distribuidores.dart';
import 'package:inject_go/screens/welcome_screen.dart';

class Routes {
  static Map<String, Widget Function(BuildContext)> list = <String, WidgetBuilder>{
    '/home': (_) => const Home(),
    '/welcome': (_) => const WelcomePage(),
    '/profile': (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String;
      return ProfileScreen(username: email);
    },
    '/profile_distribuidor': (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String;
      return ProfileScreenDistribuidor(username: email);
    },
  };

  static String initial = '/home';

  static GlobalKey<NavigatorState>? navigatorKey = GlobalKey<NavigatorState>();
}
