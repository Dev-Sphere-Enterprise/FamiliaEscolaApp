import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'pages/splash_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🔔 Handler para mensagens em background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Mensagem recebida em background: ${message.notification?.title} - ${message.data}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configura handler para mensagens em segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const FamiliaEscolaApp());
}

class FamiliaEscolaApp extends StatefulWidget {
  const FamiliaEscolaApp({super.key});

  @override
  State<FamiliaEscolaApp> createState() => _FamiliaEscolaAppState();
}

class _FamiliaEscolaAppState extends State<FamiliaEscolaApp> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔑 Solicita permissão (necessário no iOS e Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permissão: ${settings.authorizationStatus}');

    // 🔑 Pega token do dispositivo (para enviar notificações específicas)
    String? token = await messaging.getToken();
    print("📱 Token FCM: $token");

    // Listener para mensagens em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 Mensagem recebida em FOREGROUND:");
      print("Título: ${message.notification?.title}");
      print("Corpo: ${message.notification?.body}");
      print("Dados: ${message.data}");

      // Exemplo simples de alerta no app
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.notification?.title ?? "Nova mensagem")),
        );
      }
    });

    // Quando usuário clica na notificação e abre o app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 App aberto pela notificação: ${message.data}");
      // Aqui você pode redirecionar para uma tela específica (ex: chat/avisos)
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Família & Escola',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      home: const SplashPage(),
      // home: const AuthGate(),
    );
  }
}
