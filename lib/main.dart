import 'dart:convert';
import 'package:engaz_app/features/notifications_history.dart';
import 'package:engaz_app/features/order_details/order_details_page.dart';
import 'package:engaz_app/features/saved_order/view/saved_order.dart';
import 'package:engaz_app/features/splash/view/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:engaz_app/features/auth/login/view/login_screen.dart';
import 'package:engaz_app/features/auth/login/viewmodel/login_viewmodel.dart';
import 'package:engaz_app/features/splash/viewmodel/splash_viewmodel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/address/view_model/add_address_view_model.dart';
import 'features/auth/forgetPassword/viewmodel/otp_viewmodel.dart';
import 'features/localization/change_lang.dart';
import 'features/translation _request/view/translation_request_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/*Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 [Background] Full message as Map → ${jsonEncode(message.toMap())}");
  print("📦 message.data → ${message.data}");
  _showNotification(message);
}
 */

void _showNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  final title = message.data['title'] ?? notification?.title ?? 'Notification';
  final body = message.data['body'] ?? notification?.body ?? '';

  if (android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  print("🔔 Title: $title");
  print("📃 Body: $body");
}

Future<void> sendTokenToBackend(String fcmToken) async {
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('fcm_token');

  if (authToken == null) {
    print("⚠️ No auth token saved, skipping FCM token upload.");
    return;
  }

  final url =
      Uri.parse('https://wckb4f4m-3000.euw.devtunnels.ms/api/login/token');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({"token": fcmToken}),
    );
    print("✅ Token sent → ${response.statusCode}: ${response.body}");
  } catch (e) {
    print("❌ Failed to send token: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        "📥 [Foreground] Full message as Map → ${jsonEncode(message.toMap())}");
    print("📦 message.data → ${message.data}");
    _showNotification(message);
  });

  final token = await FirebaseMessaging.instance.getToken();
  print("📱 FCM Token: $token");

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SplashViewModel()),
      ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ChangeNotifierProvider(create: (_) => AddAddressViewModel()),
      ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ChangeNotifierProvider(create: (_) => OtpViewModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocalizationProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/translate': (context) => TranslationOrderApp(),
        'notifications':(_)=>NotificationsHistoryScreen(),
      },
    );
  }
}

