import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:FamiliaEscolaApp/pages/home_page.dart';
import 'package:FamiliaEscolaApp/pages/avisos_page.dart';
import 'package:FamiliaEscolaApp/pages/mensagens_page.dart';
import 'package:FamiliaEscolaApp/pages/profile_page.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return; // evita recarregar a mesma tela

    switch (index) {
      case 0: // Sair
        FirebaseAuth.instance.signOut();
        break;
      case 1: // Avisos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AvisosPage()),
        );
        break;
      case 2: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 3: // Mensagens
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MensagensPage()),
        );
        break;
      case 4: // Perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: const Text("Família & Escola"),

      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: "Sair"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Avisos"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Mensagens"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
