import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/main_scaffold.dart';

class AlunosPage extends StatelessWidget {
  const AlunosPage({super.key});

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

        Stream<QuerySnapshot> alunosStream;

        if (role == 'gestao') {
          // ✅ Gestor vê todos os alunos
          alunosStream = FirebaseFirestore.instance.collection('students').snapshots();
        } else {
          // ✅ Responsável vê só os alunos cujo CPF de responsável bate com o dele
          final cpfUsuario = userData['cpf'];

          if (cpfUsuario == null || cpfUsuario.toString().isEmpty) {
            return const Scaffold(
              body: Center(child: Text("CPF do usuário não cadastrado.")),
            );
          }

          alunosStream = FirebaseFirestore.instance
              .collection('students')
              .where('responsibleCpf', isEqualTo: cpfUsuario)
              .snapshots();
        }

        return MainScaffold(
          currentIndex: 0,
          body: StreamBuilder<QuerySnapshot>(
            stream: alunosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Nenhum aluno encontrado."));
              }

              final alunos = snapshot.data!.docs;

              return ListView.builder(
                itemCount: alunos.length,
                itemBuilder: (context, index) {
                  final aluno = alunos[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(aluno['name'] ?? 'Sem nome'),
                      subtitle: Text('Turma: ${aluno['turma'] ?? '---'}'),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
