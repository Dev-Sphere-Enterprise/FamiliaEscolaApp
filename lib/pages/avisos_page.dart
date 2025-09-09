import 'package:FamiliaEscolaApp/pages/adicionar_avisos_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  String _fmtData(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)} ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!userSnapshot.hasData || !(userSnapshot.data?.exists ?? false)) {
          return const Scaffold(body: Center(child: Text("Usuário não encontrado")));
        }

        final userData = userSnapshot.data!.data() ?? {};
        final role = (userData['role'] ?? 'responsavel') as String;
        final escolaId = userData['escolaId'] as String?;
        final cpf = userData['cpf'] as String?; // importante p/ buscar alunos

        if (escolaId == null || escolaId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Usuário não vinculado a nenhuma escola.")),
          );
        }

        final avisosQuery = FirebaseFirestore.instance
            .collection('avisos')
            .where('escolaId', isEqualTo: escolaId)
            .orderBy('data', descending: true);

        // Gestão: lista direta (sem filtro extra por aluno/turma)
        if (role == 'gestao') {
          return _ScaffoldAvisos(
            role: role,
            uid: uid,
            avisosQuery: avisosQuery,
            filtro: null, // mostra todos
          );
        }

        // Responsável: buscar alunos vinculados a este CPF na escola
        // (conforme suas regras e modelo: students.escolaId + students.responsibleCpf)
        final alunosStream = FirebaseFirestore.instance
            .collection('students')
            .where('escolaId', isEqualTo: escolaId)
            .where('responsibleCpf', isEqualTo: cpf)
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: alunosStream,
          builder: (context, alunosSnap) {
            if (alunosSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!alunosSnap.hasData) {
              return const Scaffold(body: Center(child: Text("Carregando alunos...")));
            }

            // Conjuntos com IDs dos alunos e turmas do responsável
            final alunoIds = <String>{};
            final turmaIds = <String>{};

            for (final d in alunosSnap.data!.docs) {
              alunoIds.add(d.id);
              final data = d.data();
              // tenta pegar turmaId (ou lista, se você usar)
              final tId = data['turmaId'];
              if (tId is String && tId.isNotEmpty) turmaIds.add(tId);
              final tList = data['turmaIds'];
              if (tList is List) {
                for (final t in tList) {
                  if (t is String && t.isNotEmpty) turmaIds.add(t);
                }
              }
            }

            return _ScaffoldAvisos(
              role: role,
              uid: uid,
              avisosQuery: avisosQuery,
              filtro: (aviso) {
                final destino = aviso['destino'] ?? 'escola';
                if (destino == 'escola') return true;
                if (destino == 'turma') {
                  final alvo = List<String>.from(aviso['turmaIds'] ?? const []);
                  return alvo.any(turmaIds.contains);
                }
                if (destino == 'aluno') {
                  final alvo = List<String>.from(aviso['alunoIds'] ?? const []);
                  return alvo.any(alunoIds.contains);
                }
                return false;
              },
            );
          },
        );
      },
    );
  }
}

class _ScaffoldAvisos extends StatelessWidget {
  final String role;
  final String uid;
  final Query<Map<String, dynamic>> avisosQuery;
  final bool Function(Map<String, dynamic> aviso)? filtro;

  const _ScaffoldAvisos({
    required this.role,
    required this.uid,
    required this.avisosQuery,
    required this.filtro,
  });

  String _fmtData(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)} ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: avisosQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Erro ao carregar avisos:\n$msg"),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum aviso disponível"));
          }

          // aplica filtro se necessário (responsável)
          final filtered = filtro == null
              ? snapshot.data!.docs
              : snapshot.data!.docs.where((d) => filtro!(d.data())).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("Nenhum aviso disponível para você"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final aviso = doc.data();
              final lidoPor = List<String>.from(aviso['lidoPor'] ?? []);
              final jaLido = lidoPor.contains(uid);

              final destino = (aviso['destino'] ?? 'escola') as String;
              String destinoLabel = 'Escola';
              IconData destinoIcon = Icons.campaign;
              if (destino == 'turma') {
                final count = (aviso['turmaIds'] is List) ? (aviso['turmaIds'] as List).length : 0;
                destinoLabel = count > 0 ? 'Turmas ($count)' : 'Turmas';
                destinoIcon = Icons.class_;
              } else if (destino == 'aluno') {
                final count = (aviso['alunoIds'] is List) ? (aviso['alunoIds'] as List).length : 0;
                destinoLabel = count > 0 ? 'Alunos ($count)' : 'Alunos';
                destinoIcon = Icons.person;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: jaLido ? 0 : 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  isThreeLine: true, // ✅ dá altura suficiente
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Icon(destinoIcon),
                  title: Text(
                    (aviso['titulo'] ?? '').toString(),
                    maxLines: 1, // ✅ evita estourar horizontalmente
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: jaLido ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ altura sob controle
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        (aviso['mensagem'] ?? '').toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(height: 1.25),
                      ),
                      const SizedBox(height: 6),
                      Wrap( // ✅ quebra linha se faltar espaço
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          Text(
                            _fmtData(aviso['data'] as Timestamp?),
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(destinoIcon, size: 14),
                                const SizedBox(width: 4),
                                Text(destinoLabel, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (role == 'gestao') ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility, size: 16),
                            Text('${lidoPor.length} leram', style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: role == 'responsavel'
                      ? IconButton(
                    icon: Icon(
                      jaLido ? Icons.check_circle : Icons.mark_email_unread,
                      color: jaLido ? Colors.green : Colors.red,
                    ),
                    onPressed: jaLido
                        ? null
                        : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('avisos')
                            .doc(doc.id)
                            .update({'lidoPor': FieldValue.arrayUnion([uid])});
                      } on FirebaseException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            e.code == 'permission-denied'
                                ? "Sem permissão para marcar como lido."
                                : "Erro: ${e.code}",
                          ),
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("Erro: $e")));
                      }
                    },
                  )
                      : PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showNovoAvisoDialog(
                          context,
                          escolaId: aviso['escolaId'],
                          isEdit: true,
                          docId: doc.id,
                          dados: aviso,
                        );
                      } else if (value == 'delete') {
                        try {
                          await FirebaseFirestore.instance
                              .collection('avisos')
                              .doc(doc.id)
                              .delete();
                        } on FirebaseException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro: ${e.code}")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro: $e")),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const <PopupMenuEntry<String>>[
                      PopupMenuItem(value: 'edit', child: Text("Editar")),
                      PopupMenuItem(value: 'delete', child: Text("Excluir")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: role == 'gestao'
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarAvisoPage()),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _showNovoAvisoDialog(
      BuildContext context, {
        required String escolaId,
        bool isEdit = false,
        String? docId,
        Map<String, dynamic>? dados,
      }) {
    final tituloCtrl = TextEditingController(text: dados?['titulo'] ?? '');
    final mensagemCtrl = TextEditingController(text: dados?['mensagem'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? "Editar Aviso" : "Novo Aviso"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              TextField(
                controller: mensagemCtrl,
                decoration: const InputDecoration(labelText: "Mensagem"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                final titulo = tituloCtrl.text.trim();
                final mensagem = mensagemCtrl.text.trim();

                if (titulo.isEmpty || mensagem.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preencha título e mensagem.")),
                  );
                  return;
                }

                setState(() => saving = true);
                try {
                  if (isEdit && docId != null) {
                    await FirebaseFirestore.instance.collection('avisos').doc(docId).update({
                      'titulo': titulo,
                      'mensagem': mensagem,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await FirebaseFirestore.instance.collection('avisos').add({
                      'titulo': titulo,
                      'mensagem': mensagem,
                      'data': FieldValue.serverTimestamp(),
                      'lidoPor': [],
                      'escolaId': escolaId,
                      'createdAt': FieldValue.serverTimestamp(),
                      'destino': 'escola',
                      'turmaIds': [],
                      'alunoIds': [],
                    });
                  }
                  if (context.mounted) Navigator.pop(context);
                } on FirebaseException catch (e) {
                  final msg = (e.code == 'permission-denied')
                      ? "Sem permissão para salvar avisos."
                      : (e.code == 'failed-precondition'
                      ? "Crie o índice no Firestore (where escolaId + orderBy data)."
                      : "Erro: ${e.code}");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro: $e")),
                  );
                } finally {
                  setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
