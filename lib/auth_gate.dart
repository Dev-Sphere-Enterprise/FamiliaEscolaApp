import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/add_school_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const Scaffold(
                body: Center(
                  child: Text("Erro: dados do usuário não encontrados. Faça login novamente."),
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final tipoPerfil = userData['role'] ?? 'responsavel';

            if (tipoPerfil == 'gestao') {
              final idEscola = userData['id_escola'];
              if (idEscola == null || idEscola.toString().isEmpty) {
                return const AddSchoolPage();
              }
            }

            // ✅ HomePage agora busca sozinha os dados do Firestore
            return const HomePage();
          },
        );
      },
    );
  }
}
