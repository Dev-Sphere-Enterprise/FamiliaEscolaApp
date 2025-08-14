import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';              // <- use este
import 'pages/splash_page.dart';     // <- se quiser abrir com splash

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FamiliaEscolaApp());
}

class FamiliaEscolaApp extends StatelessWidget {
  const FamiliaEscolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Família & Escola',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      // Se quiser splash primeiro, use SplashPage(); senão, vá direto pro AuthGate();
      home: const SplashPage(),
      // home: const AuthGate(),
    );
  }
}
