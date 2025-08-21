import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
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

        // 🔑 Usuário deslogado → vai pro LoginPage
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // 🔑 Usuário logado → busca dados no Firestore
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

            // ⚠️ Caso não encontre dados → volta pro LoginPage
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final tipoPerfil = userData['role'] ?? 'responsavel';
            final idEscola = userData['escolaId'];

            // Se for gestor sem escola vinculada → AddSchoolPage
            if (tipoPerfil == 'gestao' && (idEscola == null || idEscola.toString().isEmpty)) {
              return const AddSchoolPage();
            }

            // Caso contrário → HomePage com id da escola
            if (idEscola != null && idEscola.toString().isNotEmpty) {
              return HomePage();
            }

            // ⚠️ Responsável sem escola vinculada → erro de fluxo
            return const Scaffold(
              body: Center(
                child: Text("Você ainda não está vinculado a nenhuma escola."),
              ),
            );
          },
        );
      },
    );
  }
}
