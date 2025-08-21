import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/main_scaffold.dart';
import 'aluno_detalhes_page.dart';

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
        final escolaIdUser = userData['escolaId'];

        Stream<QuerySnapshot> alunosStream;

        if (role == 'gestao') {
          // ✅ Gestor só vê os alunos da escola dele
          alunosStream = FirebaseFirestore.instance
              .collection('students')
              .where('escolaId', isEqualTo: escolaIdUser)
              .snapshots();
        } else {
          // ✅ Responsável vê só os alunos cujo CPF bate com o dele
          final cpfUsuario = userData['cpf'];

          if (cpfUsuario == null || cpfUsuario.toString().isEmpty) {
            return const Scaffold(
              body: Center(child: Text("CPF do usuário não cadastrado.")),
            );
          }

          alunosStream = FirebaseFirestore.instance
              .collection('students')
              .where('responsibleCpf', isEqualTo: cpfUsuario)
              .where('escolaId', isEqualTo: escolaIdUser) // garante a mesma escola
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
                  final alunoDoc = alunos[index];
                  final aluno = alunoDoc.data() as Map<String, dynamic>;
                  final escolaIdAluno = aluno['escolaId'];

                  return StreamBuilder<DocumentSnapshot>(
                    stream: escolaIdAluno != null
                        ? FirebaseFirestore.instance.collection('escolas').doc(escolaIdAluno).snapshots()
                        : const Stream.empty(),
                    builder: (context, escolaSnapshot) {
                      String escolaNome = "---";
                      if (escolaSnapshot.hasData && escolaSnapshot.data!.exists) {
                        final escolaData = escolaSnapshot.data!.data() as Map<String, dynamic>;
                        escolaNome = escolaData['nome'] ?? "---";
                      }

                      return Card(
                        child: ListTile(
                          title: Text(aluno['nome'] ?? 'Sem nome'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Escola: $escolaNome'),
                              if (aluno['responsibleName'] != null)
                                Text('Responsável: ${aluno['responsibleName']}'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlunoDetalhesPage(
                                    alunoId: alunoDoc.id,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Ver detalhes"),
                          ),
                        ),
                      );
                    },
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
