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
          await FirebaseFirestore.instance.collection('distribuidores').doc(distributorSnapshot.docs.first.id).update({
            'fcmToken': token,
          });
        } else {
          // Salva o token para o profissional
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            await FirebaseFirestore.instance.collection('users').doc(userSnapshot.docs.first.id).update({
              'fcmToken': token,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao gerar token do dispositivo: $e');
    }
  }

  // Escuta mensagens enquanto o app está no foreground
  void _onMessage() {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _notificationService.showLocalNotification(
          CustomNotification(
            id: android.hashCode,
            title: notification.title!,
            body: notification.body!,
            payload: message.data['route'] ?? '',
          ),
        );
      }
    });
  }

  // Escuta cliques em notificações
  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final String route = message.data['route'] ?? '/';
      Navigator.of(Routes.navigatorKey!.currentContext!).pushNamed(route);
    });
  }
}
