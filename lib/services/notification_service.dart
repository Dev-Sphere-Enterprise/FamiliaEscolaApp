import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:FamiliaEscolaApp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Páginas do app
import 'package:FamiliaEscolaApp/pages/avisos_page.dart';
import 'package:FamiliaEscolaApp/pages/mensagens_page.dart';
import 'package:FamiliaEscolaApp/pages/alunos_page.dart';
import 'package:FamiliaEscolaApp/pages/turmas_page.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static StreamSubscription? _onMessageSubscription;
  static StreamSubscription? _onMessageOpenedAppSubscription;

  /// Inicializa todo o serviço de FCM + notificações locais
  static Future<void> init() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Configura notificações locais
    await _configureLocalNotifications();

    // Handler para background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Permissões
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Token do dispositivo
    final token = await messaging.getToken();
    print("📱 Token FCM: $token");

    // Foreground
    _onMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          print("📨 Foreground: ${message.notification?.title}");
          await _showNotification(
            title: message.notification?.title ?? "Notificação",
            body: message.notification?.body ?? "",
            data: message.data,
          );
        });

    // Quando usuário abre a notificação
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print("🚀 Abriu pelo push: ${message.data}");
          _handleNotificationClick(message.data);
        });

    // Se app iniciou por push
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 App iniciado via push: ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data);
    }
  }

  /// Configura notificações locais
  static Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = _parsePayload(details.payload!);
          _handleNotificationClick(data);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificações Importantes',
      description: 'Este canal é usado para notificações importantes.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Mostrar notificação local
  static Future<void> _showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificações Importantes',
      channelDescription: 'Este canal é usado para notificações importantes.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final payload = _convertDataToPayload(data);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Redirecionar usuário com base no "type"
  static void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'aviso') {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const AvisosPage()));
    } else if (type == 'mensagem') {
      final escolaId = data['escolaId'];
      final conversaId = data['conversaId'];
      if (escolaId != null && conversaId != null) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => MensagensThreadPage(escolaId: escolaId, conversaId: conversaId),
        ));
      }
    } else if (type == 'chat') {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const MensagensPage()));
    } else if (type == 'aluno') {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const AlunosPage()));
    } else if (type == 'turma') {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const TurmasPage()));
    } else {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Notificação recebida, mas sem ação definida.")),
      );
    }
  }

  /// Background handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("📩 Mensagem em background: ${message.data}");

    await _showNotification(
      title: message.notification?.title ?? 'Nova notificação',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  /// Helpers
  static String _convertDataToPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  static Map<String, String> _parsePayload(String payload) {
    final Map<String, String> data = {};
    for (final pair in payload.split('&')) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) data[keyValue[0]] = keyValue[1];
    }
    return data;
  }
}
