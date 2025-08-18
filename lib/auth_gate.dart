import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        // Se o usuário está logado, agora usamos um StreamBuilder para ouvir as alterações no perfil
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Isso pode acontecer brevemente se o usuário for recém-criado.
              // Pode ser bom deslogar para evitar loops ou mostrar uma mensagem específica.
              FirebaseAuth.instance.signOut();
              return const Scaffold(
                body: Center(child: Text("Erro: dados do usuário não encontrados. Faça login novamente.")),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final nome = userData['name'] ?? 'Usuário';
            final tipoPerfil = userData['role'] ?? 'responsavel';

            if (tipoPerfil == 'gestao') {
              final idEscola = userData['id_escola'];
              if (idEscola == null || idEscola.toString().isEmpty) {
                // Se for gestor e NÃO tiver escola, vai para a tela de cadastro de escola
                return const AddSchoolPage();
              }
            }

            // Se for responsável ou gestor com escola, vai para a HomePage
            return HomePage(
              nomeUsuario: nome,
              tipoPerfil: tipoPerfil,
            );
          },
        );
      },
    );
  }
}