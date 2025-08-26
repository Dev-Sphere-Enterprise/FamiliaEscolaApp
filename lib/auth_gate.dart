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
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final tipoPerfil = userData['role'];
            final idEscola = userData['escolaId'];

            if (tipoPerfil == 'gestao' && (idEscola == null || idEscola.toString().isEmpty)) {
              return const AddSchoolPage();
            }

            if (idEscola != null && idEscola.toString().isNotEmpty) {
              return const HomePage();
            }

            // Caso de um responsável que, por algum erro, não foi vinculado.
            return const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Você ainda não está vinculado a nenhuma escola. Contate a administração."),
                ),
              ),
            );
          },
        );
      },
    );
  }
}