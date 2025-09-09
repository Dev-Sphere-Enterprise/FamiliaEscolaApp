import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
    // Nome
    final nomeCtrl = TextEditingController(text: aluno['nome'] ?? "");

    // Data de nascimento (pode ser Timestamp ou String)
    String nascimentoStr = "";
    final nascimento = aluno['dataNascimento'];
    if (nascimento is Timestamp) {
      final dt = nascimento.toDate();
      nascimentoStr =
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } else if (nascimento is String) {
      nascimentoStr = nascimento;
    }
    final nascimentoCtrl = TextEditingController(text: nascimentoStr);

    // Responsável
    final respNomeCtrl =
    TextEditingController(text: aluno['responsibleName'] ?? "");
    final respCpfCtrl =
    TextEditingController(text: aluno['responsibleCpf'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("✏️ Editar Aluno"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                    labelText: "Nome do Aluno", prefixIcon: Icon(Icons.person)),
              ),
              TextField(
                controller: nascimentoCtrl,
                decoration: const InputDecoration(
                    labelText: "Data de Nascimento",
                    prefixIcon: Icon(Icons.cake)),
              ),
              TextField(
                controller: respNomeCtrl,
                decoration: const InputDecoration(
                    labelText: "Nome do Responsável",
                    prefixIcon: Icon(Icons.family_restroom)),
              ),
              TextField(
                controller: respCpfCtrl,
                decoration: const InputDecoration(
                    labelText: "CPF do Responsável",
                    prefixIcon: Icon(Icons.badge)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .update({
                "nome": nomeCtrl.text.trim(),
                "dataNascimento": nascimentoCtrl.text.trim(), // ⚠️ continua salvando como String
                "responsibleName": respNomeCtrl.text.trim(),
                "responsibleCpf": respCpfCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            label: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _excluirAluno(BuildContext context, String alunoId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("⚠️ Excluir Aluno"),
        content: const Text("Tem certeza que deseja excluir este aluno?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text("Excluir"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .delete();
              Navigator.pop(context); // fecha o dialog
              Navigator.pop(context); // volta da tela de detalhes
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
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
            centerTitle: true,
            backgroundColor: Colors.blue.shade700,
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

              // ✅ trata dataNascimento
              String nascimentoStr = "---";
              final nascimento = aluno['dataNascimento'];
              if (nascimento is Timestamp) {
                final dt = nascimento.toDate();
                nascimentoStr =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
              } else if (nascimento is String) {
                nascimentoStr = nascimento;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade200,
                      child: const Icon(Icons.person,
                          size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    aluno['nome'] ?? '---',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _infoCard(Icons.cake, "Data de Nascimento", nascimentoStr),
                  _infoCard(Icons.family_restroom, "Responsável",
                      aluno['responsibleName'] ?? "---"),
                  _infoCard(Icons.badge, "CPF do Responsável",
                      aluno['responsibleCpf'] ?? "---"),

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
                        final escolaData =
                        escolaSnapshot.data!.data() as Map<String, dynamic>;
                        escolaNome = escolaData['nome'] ?? "---";
                      }
                      return _infoCard(Icons.school, "Escola", escolaNome);
                    },
                  ),
                  const SizedBox(height: 8),

                  if (turmaId != null && escolaId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('escolas')
                          .doc(escolaId)
                          .collection('turmas')
                          .doc(turmaId)
                          .snapshots(),
                      builder: (context, turmaSnapshot) {
                        if (turmaSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _infoCard(
                              Icons.group, "Turma", "Carregando...");
                        }
                        if (turmaSnapshot.hasData &&
                            turmaSnapshot.data!.exists) {
                          final turmaData =
                          turmaSnapshot.data!.data() as Map<String, dynamic>;
                          return _infoCard(Icons.group, "Turma",
                              turmaData['nome'] ?? "---");
                        }
                        return _infoCard(
                            Icons.group, "Turma", "Não matriculado");
                      },
                    )
                  else
                    _infoCard(Icons.group, "Turma", "Não matriculado"),
                ],
              );
            },
          ),
          floatingActionButton: ehGestor
              ? SpeedDial(
            icon: Icons.settings,
            activeIcon: Icons.close,
            backgroundColor: Colors.blue.shade700,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.edit),
                label: "Editar",
                onTap: () async {
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
              SpeedDialChild(
                child: const Icon(Icons.delete, color: Colors.red),
                label: "Excluir",
                onTap: () => _excluirAluno(context, alunoId),
              ),
            ],
          )
              : null,
        );
      },
    );
  }
}
