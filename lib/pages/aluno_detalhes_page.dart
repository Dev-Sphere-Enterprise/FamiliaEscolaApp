import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlunoDetalhesPage extends StatelessWidget {
  final String alunoId;

  const AlunoDetalhesPage({super.key, required this.alunoId});

  Future<bool> _usuarioEhGestor() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final userDoc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return userDoc.data()?['role'] == "gestao";
  }

  void _editarAluno(
      BuildContext context, String alunoId, Map<String, dynamic> aluno) {
    final nomeCtrl = TextEditingController(text: aluno['nome'] ?? "");
    final nascimentoCtrl =
    TextEditingController(text: aluno['dataNascimento'] ?? "");
    final respNomeCtrl =
    TextEditingController(text: aluno['responsibleName'] ?? "");
    final respCpfCtrl =
    TextEditingController(text: aluno['responsibleCpf'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Aluno"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: "Nome do Aluno"),
              ),
              TextField(
                controller: nascimentoCtrl,
                decoration:
                const InputDecoration(labelText: "Data de Nascimento"),
              ),
              TextField(
                controller: respNomeCtrl,
                decoration:
                const InputDecoration(labelText: "Nome do Responsável"),
              ),
              TextField(
                controller: respCpfCtrl,
                decoration:
                const InputDecoration(labelText: "CPF do Responsável"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .update({
                "nome": nomeCtrl.text.trim(),
                "dataNascimento": nascimentoCtrl.text.trim(),
                "responsibleName": respNomeCtrl.text.trim(),
                "responsibleCpf": respCpfCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _excluirAluno(BuildContext context, String alunoId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Aluno"),
        content: const Text("Tem certeza que deseja excluir este aluno?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .delete();
              Navigator.pop(context); // fecha o dialog
              Navigator.pop(context); // volta da tela de detalhes
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _usuarioEhGestor(),
      builder: (context, gestorSnapshot) {
        final ehGestor = gestorSnapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Detalhes do Aluno"),
            actions: ehGestor
                ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final alunoDoc = await FirebaseFirestore.instance
                      .collection("students")
                      .doc(alunoId)
                      .get();
                  if (alunoDoc.exists) {
                    _editarAluno(context, alunoId,
                        alunoDoc.data() as Map<String, dynamic>);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _excluirAluno(context, alunoId),
              ),
            ]
                : null,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(alunoId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Aluno não encontrado."));
              }

              final aluno = snapshot.data!.data() as Map<String, dynamic>;
              final escolaId = aluno['escolaId'];
              final turmaId = aluno['turmaId'];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Nome: ${aluno['nome'] ?? '---'}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                      "Data de Nascimento: ${aluno['dataNascimento'] ?? '---'}"),
                  const SizedBox(height: 12),

                  Text("Responsável: ${aluno['responsibleName'] ?? '---'}"),
                  const SizedBox(height: 8),
                  Text("CPF do Responsável: ${aluno['responsibleCpf'] ?? '---'}"),
                  const SizedBox(height: 16),

                  // 🔹 Buscar nome da escola
                  StreamBuilder<DocumentSnapshot>(
                    stream: escolaId != null
                        ? FirebaseFirestore.instance
                        .collection('escolas')
                        .doc(escolaId)
                        .snapshots()
                        : const Stream.empty(),
                    builder: (context, escolaSnapshot) {
                      String escolaNome = "---";
                      if (escolaSnapshot.hasData &&
                          escolaSnapshot.data!.exists) {
                        final escolaData = escolaSnapshot.data!.data()
                        as Map<String, dynamic>;
                        escolaNome = escolaData['nome'] ?? "---";
                      }
                      return Text("Escola: $escolaNome");
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Buscar nome da turma
                  if (turmaId != null && escolaId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('escolas')
                          .doc(escolaId)
                          .collection('turmas')
                          .doc(turmaId)
                          .snapshots(),
                      builder: (context, turmaSnapshot) {
                        if (turmaSnapshot.connectionState == ConnectionState.waiting) {
                          return const Text("Turma: Carregando...");
                        }
                        if (turmaSnapshot.hasData && turmaSnapshot.data!.exists) {
                          final turmaData = turmaSnapshot.data!.data() as Map<String, dynamic>;
                          return Text('Turma: ${turmaData['nome'] ?? "Sem nome"}');
                        }
                        return const Text("Turma: Não matriculado");
                      },
                    )
                  else
                    const Text("Turma: Não matriculado"),
                ],
              );
            },
          ),
        );
      },
    );
  }
}