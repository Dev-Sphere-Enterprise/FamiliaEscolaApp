import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mensagens_page.dart'; // para usar MensagensThreadPage

class ResponsaveisPage extends StatelessWidget {
  final String escolaId;
  final String gestorUid;
  const ResponsaveisPage({super.key, required this.escolaId, required this.gestorUid});

  /// Cria um ID determinístico para chat 1-1
  String _pairKey(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Cria ou retorna o ID da conversa 1-1
  Future<String> _openOrCreate1to1({
    required String otherUid,
    required BuildContext context,
  }) async {
    final pairId = _pairKey(gestorUid, otherUid);
    final conversaRef = FirebaseFirestore.instance
        .collection('escolas')
        .doc(escolaId)
        .collection('conversas')
        .doc(pairId);

    final snap = await conversaRef.get();
    if (!snap.exists) {
      // pega dados do outro usuário
      final otherDoc =
      await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      final otherData = otherDoc.data() ?? {};

      final gestorDoc =
      await FirebaseFirestore.instance.collection('users').doc(gestorUid).get();
      final gestorData = gestorDoc.data() ?? {};

      await conversaRef.set({
        'escolaId': escolaId,
        'tipo': '1-1',
        'participantes': [gestorUid, otherUid],
        'participantesInfo': {
          gestorUid: {'nome': gestorData['nome'] ?? 'Gestor', 'role': gestorData['role']},
          otherUid: {'nome': otherData['nome'] ?? 'Responsável', 'role': otherData['role']},
        },
        'titulo': otherData['nome'] ?? 'Conversa',
        'ultimoTexto': '',
        'atualizadoEm': FieldValue.serverTimestamp(),
        'unread': {gestorUid: 0, otherUid: 0},
      });
    }
    return conversaRef.id;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'responsavel')
        .where('escolaId', isEqualTo: escolaId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Responsáveis")),
      body: StreamBuilder<QuerySnapshot>(
        stream: query,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum responsável encontrado"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final uid = d.id;
              final nome = (data['nome'] ?? "Sem nome").toString();
              final cpf = (data['cpf'] ?? "").toString();
              final email = (data['email'] ?? "").toString();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(nome),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (email.isNotEmpty) Text(email),
                      if (cpf.isNotEmpty) Text("CPF: $cpf"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () async {
                      final conversaId = await _openOrCreate1to1(
                        otherUid: uid,
                        context: context,
                      );
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MensagensThreadPage(
                              escolaId: escolaId,
                              conversaId: conversaId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .where('responsibleCpf', isEqualTo: cpf)
                          .where('escolaId', isEqualTo: escolaId)
                          .snapshots(),
                      builder: (context, snapAlunos) {
                        if (snapAlunos.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapAlunos.hasData ||
                            snapAlunos.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Nenhum aluno vinculado"),
                          );
                        }
                        final alunos = snapAlunos.data!.docs;
                        return Column(
                          children: alunos.map((a) {
                            final aluno = a.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.school),
                              title: Text(aluno['nome'] ?? '---'),
                              subtitle: Text(
                                  "Nascimento: ${aluno['dataNascimento'] ?? '--/--/----'}"),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
