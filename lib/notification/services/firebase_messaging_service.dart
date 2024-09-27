import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/notification/routes.dart';
import 'package:inject_go/notification/services/notification_service.dart';

/// Serviço responsável por gerenciar as notificações push usando Firebase Cloud Messaging (FCM).
/// Ele lida com o recebimento de notificações enquanto o aplicativo está em foreground e background,
/// e trata as navegações quando o usuário clica nas notificações.
class FirebaseMessagingService {
  // Serviço responsável por exibir notificações locais no dispositivo
  final NotificationService _notificationService;

  FirebaseMessagingService(this._notificationService);

  /// Inicializa o serviço de mensagens do Firebase.
  /// Configura as notificações a serem exibidas com som, alerta e ícone de badge quando o app está em foreground.
  Future<void> initialize() async {
    // Configura a exibição de notificações em primeiro plano (foreground)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      badge: true,
      sound: true,
      alert: true,
    );

    // Inicializa os ouvintes para mensagens e cliques nas notificações
    _onMessage();  // Para quando o app está aberto
    _onMessageOpenedApp();  // Para quando o app é aberto via notificação
  }

  /// Ouvinte que lida com notificações recebidas enquanto o app está em foreground (ativo).
  /// Exibe notificações locais usando o NotificationService e gerencia a navegação com base nos dados recebidos.
  void _onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Extrai as informações da notificação
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Exibe a notificação localmente se estiver disponível
      if (notification != null && android != null) {
        _exibirNotificacaoLocal(notification);
        
        // Navega para a rota correta baseada nos dados da mensagem
        _navegarComBaseNaMensagem(message.data);
      }
    });
  }

  /// Exibe uma notificação local com base nos detalhes fornecidos.
  void _exibirNotificacaoLocal(RemoteNotification notification) {
    CustomNotification customNotification = CustomNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Gera um ID único para a notificação
      title: notification.title ?? 'Notificação',
      body: notification.body ?? 'Você recebeu uma nova mensagem',
    );

    // Exibe a notificação usando NotificationService
    _notificationService.showLocalNotification(customNotification);
  }

  /// Processa os dados da mensagem e navega para a rota correta.
  void _navegarComBaseNaMensagem(Map<String, dynamic> data) {
    final String route = data['route'] ?? '/home'; // Rota padrão é '/home' se não estiver definida
    final String? distribuidorId = data['distribuidorId']?.toString();
    final String? email = data['email']?.toString();
    final int initialTab = int.tryParse(data['initialTab']?.toString() ?? '0') ?? 0;

    debugPrint('Route: $route, DistribuidorId: $distribuidorId, Email: $email, InitialTab: $initialTab');

    // Navega com base na rota e parâmetros recebidos
    if (route == '/minhas_vendas' && distribuidorId != null) {
      _navegarParaMinhasVendas(distribuidorId, email, initialTab);
    } else if (route == '/minhas_compras' && email != null) {
      _navegarParaMinhasCompras(email, initialTab);
    } else if (route == '/home') {
      Navigator.of(Routes.navigatorKey.currentContext!).pushNamed('/home');
    }
  }

  /// Navega para a tela de "Minhas Vendas", passando os argumentos corretos.
  void _navegarParaMinhasVendas(String distribuidorId, String? email, int initialTab) {
    Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
      '/minhas_vendas',
      arguments: {
        'distribuidorId': distribuidorId,
        'email': email,
        'initialTab': initialTab,
      },
    );
  }

  /// Navega para a tela de "Minhas Compras", passando os argumentos corretos.
  void _navegarParaMinhasCompras(String email, int initialTab) {
    Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
      '/minhas_compras',
      arguments: {
        'profissionalId': email,
        'initialTab': initialTab,
      },
    );
  }

  /// Ouvinte que lida com notificações quando o app é aberto via notificação (em segundo plano ou fechado).
  /// Navega para a rota correta baseada nos dados recebidos.
  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Verifica se a mensagem contém uma rota
      if (message.data.containsKey('route')) {
        final String route = message.data['route'] ?? '/';
        final String? distribuidorId = message.data['distribuidorId'];
        final String? profissionalId = message.data['profissionalId'];
        final int initialTab = int.tryParse(message.data['initialTab'] ?? '0') ?? 0;

        // Navega para a rota correta se a rota existir no mapa de rotas
        if (Routes.list.containsKey(route)) {
          Navigator.of(Routes.navigatorKey.currentContext!).pushNamed(
            route,
            arguments: _getArgumentsForRoute(route, distribuidorId, profissionalId, initialTab),
          );
        }
      }
    });
  }

  /// Constrói os argumentos corretos para cada rota baseada na rota fornecida e parâmetros.
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
    // Se não precisar de argumentos ou não for aplicável, retorna null
    return null;
  }
}
