import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inject_go/notification/routes.dart';
import 'package:inject_go/notification/services/notification_service.dart';

class FirebaseMessagingService {
  final NotificationService _notificationService;

  FirebaseMessagingService(this._notificationService);

  // Inicializa o Firebase Messaging e salva o token FCM
  Future<void> initialize() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      badge: true,
      sound: true,
      alert: true,
    );

    await _saveDeviceFirebaseToken();  // Obtem e salva o token FCM
    _onMessage();  // Escuta mensagens enquanto o app está em foreground
    _onMessageOpenedApp();  // Escuta cliques em notificações
  }

  // Obtem e salva o token FCM no Firestore
  Future<void> _saveDeviceFirebaseToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('Token do dispositivo: $token');

      // Verifica se o usuário está logado
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        final email = currentUser.email;

        // Verifica se é distribuidor ou profissional e salva o token no Firestore
        final distributorSnapshot = await FirebaseFirestore.instance
            .collection('distribuidores')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (distributorSnapshot.docs.isNotEmpty) {
          // Salva o token para o distribuidor
          _updateTokens('distribuidores', distributorSnapshot.docs.first.id, token);
        } else {
          // Salva o token para o profissional
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            _updateTokens('users', userSnapshot.docs.first.id, token);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao gerar token do dispositivo: $e');
    }
  }

  // Função para adicionar o token ao array de tokens FCM do usuário
  Future<void> _updateTokens(String collection, String docId, String token) async {
    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    // Adicionar token ao array de tokens no Firestore, garantindo que não haja duplicatas
    await docRef.set({
      'fcmTokens': FieldValue.arrayUnion([token]),  // Adiciona o token ao array
    }, SetOptions(merge: true));
  }

  void _onMessage() {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        final String? route = message.data['route'];
        final String? email = message.data['email'];

        if (route != null && email != null) {
          Navigator.of(Routes.navigatorKey!.currentContext!).pushNamed(
            route,
            arguments: email,  // Passa o email como argumento
          );
        }
      }
    });
  }

  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final String route = message.data['route'] ?? '/';
      final String? distribuidorId = message.data['distribuidorId'];
      final int initialTab = int.tryParse(message.data['initialTab'] ?? '0') ?? 0;

      if (distribuidorId != null) {
        Navigator.of(Routes.navigatorKey!.currentContext!).pushNamed(
          route,
          arguments: {
            'distribuidorId': distribuidorId,  // Passa o ID do distribuidor
            'initialTab': initialTab,  // Passa a aba inicial
          },
        );
      }
    });
  }

}
