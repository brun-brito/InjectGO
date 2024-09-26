import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/notification/routes.dart';
import 'package:inject_go/notification/services/notification_service.dart';

class FirebaseMessagingService {
  // ignore: unused_field
  final NotificationService _notificationService;

  FirebaseMessagingService(this._notificationService);

  // Inicializa o Firebase Messaging e salva o token FCM
  Future<void> initialize() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      badge: true,
      sound: true,
      alert: true,
    );

    _onMessage();  // Escuta mensagens enquanto o app está em foreground
    _onMessageOpenedApp();  // Escuta cliques em notificações
  }

  void _onMessage() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Criar um objeto CustomNotification com os detalhes da notificação
      CustomNotification customNotification = CustomNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único para cada notificação
        title: notification.title ?? 'Notificação',
        body: notification.body ?? 'Você recebeu uma nova mensagem',
      );

      // Exibir a notificação em foreground usando NotificationService
      _notificationService.showLocalNotification(customNotification);

      // Lógica de navegação
      final String route = message.data['route'] ?? '/home';
      final String? distribuidorId = message.data['distribuidorId']?.toString();
      final String? email = message.data['email']?.toString();
      final String? initialTabString = message.data['initialTab']?.toString();
      final int initialTab = int.tryParse(initialTabString ?? '0') ?? 0;

      // Debug: Imprimindo os valores recebidos

      // Navegar para a rota correta
      if (route == '/minhas_vendas' && distribuidorId != null) {
        Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
          route,
          arguments: {
            'distribuidorId': distribuidorId,
            'email': email,
            'initialTab': initialTab,
          },
        );
      } else if (route == '/minhas_compras' && email != null) {
        Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
          route,
          arguments: {
            'email': email,
            'initialTab': initialTab,
          },
        );
      } else if (route == '/home') {
        Navigator.of(Routes.navigatorKey.currentContext!).pushNamed('/home');
      } else {
      }
    }
  });
}

  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('route')) {
        final String route = message.data['route'] ?? '/';
        final String? distribuidorId = message.data['distribuidorId'];
        final String? profissionalId = message.data['profissionalId'];
        final int initialTab = int.tryParse(message.data['initialTab'] ?? '0') ?? 0;

        // Verifique se a rota existe na lista de rotas antes de navegar
        if (Routes.list.containsKey(route)) {
          Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
            route,
            arguments: _getArgumentsForRoute(route, distribuidorId, profissionalId, initialTab),
          );
        } else {
        }
      }
    });
  }

  // Função para construir os argumentos corretos para cada rota
  Map<String, dynamic>? _getArgumentsForRoute(String route, String? distribuidorId, String? profissionalId, int initialTab) {
    if (route == '/minhas_vendas' && distribuidorId != null) {
      return {
        'distribuidorId': distribuidorId,
        'initialTab': initialTab,
      };
    } else if (route == '/minhas_compras' && profissionalId != null) {
      return {
        'profissionalId': profissionalId,
        'initialTab': initialTab,
      };
    }
    // Se não precisar de argumentos, retorne null
    return null;
  }

}
