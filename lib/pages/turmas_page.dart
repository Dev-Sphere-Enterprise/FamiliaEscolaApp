import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_turma_page.dart';
import '../widgets/main_scaffold.dart';

class TurmasPage extends StatelessWidget {
  const TurmasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Usuário não encontrado")),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'responsavel';
        final escolaId = userData['escolaId'];

        if (role != 'gestao') {
          return const Scaffold(
            body: Center(child: Text("Acesso negado")),
          );
        }

        return MainScaffold(
          currentIndex: 3,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('escolas')
                .doc(escolaId)
                .collection('turmas')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Nenhuma turma encontrada."));
              }

              final turmas = snapshot.data!.docs;

              return ListView.builder(
                itemCount: turmas.length,
                itemBuilder: (context, index) {
                  final turmaDoc = turmas[index];
                  final turma = turmaDoc.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(turma['nome'] ?? 'Sem nome'),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTurmaPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}