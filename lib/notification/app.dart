import 'package:flutter/material.dart';
import 'package:inject_go/notification/routes.dart';
import 'package:inject_go/notification/services/firebase_messaging_service.dart';
import 'package:inject_go/notification/services/notification_service.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    initilizeFirebaseMessaging();
    checkNotifications();
  }

  initilizeFirebaseMessaging() async {
    await Provider.of<FirebaseMessagingService>(context, listen: false).initialize();
  }

  checkNotifications() async {
    await Provider.of<NotificationService>(context, listen: false).checkForNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: Routes.list,
      initialRoute: Routes.initial,
      navigatorKey: Routes.navigatorKey,
    );
  }
}