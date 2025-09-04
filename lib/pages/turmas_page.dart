import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_turma_page.dart';
import 'turma_detalhes_page.dart';
import '../widgets/main_scaffold.dart';

class TurmasPage extends StatelessWidget {
  const TurmasPage({super.key});

  Future<void> _editarTurma(
      BuildContext context, String escolaId, String turmaId, String nomeAtual) async {
    final controller = TextEditingController(text: nomeAtual);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Turma"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nome da turma"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('escolas')
                    .doc(escolaId)
                    .collection('turmas')
                    .doc(turmaId)
                    .update({"nome": controller.text.trim()});
              }
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirTurma(
      BuildContext context, String escolaId, String turmaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Turma"),
        content: const Text("Tem certeza que deseja excluir esta turma?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('escolas')
          .doc(escolaId)
          .collection('turmas')
          .doc(turmaId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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
                  final turmaNome = turma['nome'] ?? 'Sem nome';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        turmaNome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'editar') {
                            _editarTurma(
                                context, escolaId, turmaDoc.id, turmaNome);
                          } else if (value == 'excluir') {
                            _excluirTurma(context, escolaId, turmaDoc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'editar',
                            child: Text("Editar"),
                          ),
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Text("Excluir"),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TurmaDetalhesPage(
                              escolaId: escolaId,
                              turmaId: turmaDoc.id,
                              turmaNome: turmaNome,
                            ),
                          ),
                        );
                      },
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
