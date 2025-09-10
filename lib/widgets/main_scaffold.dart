import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:FamiliaEscolaApp/pages/home_page.dart';
import 'package:FamiliaEscolaApp/pages/avisos_page.dart';
import 'package:FamiliaEscolaApp/pages/mensagens_page.dart';
import 'package:FamiliaEscolaApp/pages/profile_page.dart';
import 'package:FamiliaEscolaApp/pages/forumPage.dart'; // ✅ importa a ForumPage

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
    // if (index == currentIndex) return;

    switch (index) {
      case 0:
        FirebaseAuth.instance.signOut();
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AvisosPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MensagensPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: const Text("Família & Escola"),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum),
            tooltip: "Fórum",
            onPressed: () async {
              if (uid == null) return;

              final userDoc = await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .get();
              final userData = userDoc.data() ?? {};
              final escolaId = userData["escolaId"];

              if (escolaId != null && escolaId.toString().isNotEmpty) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForumPage(escolaId: escolaId),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Você não está vinculado a uma escola."),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: uid == null
          ? _buildBottomNav(context, 0)
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return _buildBottomNav(context, 0);
          }

          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final escolaId = userData["escolaId"];
          if (escolaId == null || escolaId.toString().isEmpty) {
            return _buildBottomNav(context, 0);
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("escolas")
                .doc(escolaId)
                .collection("conversas")
                .where("participantes", arrayContains: uid)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final unreadMap =
                  Map<String, dynamic>.from(data["unread"] ?? {});
                  unreadCount += (unreadMap[uid] is int)
                      ? unreadMap[uid] as int
                      : 0;
                }
              }

              return _buildBottomNav(context, unreadCount);
            },
          );
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  /// Cria a BottomNavigationBar já com badge de mensagens
  Widget _buildBottomNav(BuildContext context, int unreadCount) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => _onTap(context, index),
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app), label: "Sair"),
        const BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: "Avisos"),
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.message),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? "9+" : "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: "Mensagens",
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}
