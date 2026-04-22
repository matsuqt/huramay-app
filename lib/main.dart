// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth_screens.dart';

// 1. NEW: Create a Global Key so we can force a popup banner from anywhere in the app
final GlobalKey<ScaffoldMessengerState> globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(); 

  // Request Android 13+ Permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  print('User granted permission: ${settings.authorizationStatus}');

  // 2. NEW: The Foreground Listener (Catches messages when the app is actively OPEN)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      // Force a custom in-app banner to appear
      globalMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            "${message.notification!.title}: ${message.notification!.body}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A0088), // Official Blue Branding
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating, 
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: globalMessengerKey, // 3. NEW: Attach the key to the app wrapper
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), 
    );
  }
}