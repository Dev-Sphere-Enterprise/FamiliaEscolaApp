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
          alunosStream = FirebaseFirestore.instance
              .collection('students')
              .where('escolaId', isEqualTo: escolaIdUser)
              .snapshots();
        } else {
          final cpfUsuario = userData['cpf'];

          if (cpfUsuario == null || cpfUsuario.toString().isEmpty) {
            return const Scaffold(
              body: Center(child: Text("CPF do usuário não cadastrado.")),
            );
          }

          alunosStream = FirebaseFirestore.instance
              .collection('students')
              .where('responsibleCpf', isEqualTo: cpfUsuario)
              .where('escolaId', isEqualTo: escolaIdUser)
              .snapshots();
        }

        return MainScaffold(
          currentIndex: 0,
          body: Scaffold(
            body: StreamBuilder<QuerySnapshot>(
              stream: alunosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum aluno encontrado.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                final alunos = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    (aluno['nome'] != null && aluno['nome'].toString().isNotEmpty)
                                        ? aluno['nome'][0].toUpperCase()
                                        : "?",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno['nome'] ?? 'Sem nome',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Escola: $escolaNome",
                                          style: TextStyle(color: Colors.grey.shade700)),
                                      if (aluno['responsibleName'] != null)
                                        Text("Responsável: ${aluno['responsibleName']}",
                                            style: TextStyle(color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text("Detalhes"),
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
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
