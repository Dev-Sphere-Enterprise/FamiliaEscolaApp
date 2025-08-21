import 'package:FamiliaEscolaApp/pages/adicionar_avisos_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

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

        if (escolaId == null || escolaId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Usuário não vinculado a nenhuma escola.")),
          );
        }

        final avisosQuery = FirebaseFirestore.instance
            .collection('avisos')
            .where('escolaId', isEqualTo: escolaId)
            .orderBy('data', descending: true);

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

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final aviso = doc.data();
                  final lidoPor = List<String>.from(aviso['lidoPor'] ?? []);
                  final jaLido = lidoPor.contains(uid);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(aviso['titulo'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aviso['mensagem'] ?? ''),
                          if (aviso['data'] != null)
                            Text(
                              (aviso['data'] as Timestamp).toDate().toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                .update({
                              'lidoPor': FieldValue.arrayUnion([uid])
                            });
                          } on FirebaseException catch (e) {
                            // Provável PERMISSION_DENIED com suas regras atuais
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.code == 'permission-denied'
                                      ? "Sem permissão para marcar como lido."
                                      : "Erro: ${e.code}",
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erro: $e")),
                            );
                          }
                        },
                      )
                          : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showNovoAvisoDialog(
                              context,
                              escolaId: escolaId,
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
                }).toList(),
              );
            },
          ),
          floatingActionButton: role == 'gestao'
              ? FloatingActionButton(
            onPressed: () => _showNovoAvisoDialog(context, escolaId: escolaId),
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
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
                      'escolaId': escolaId, // mantém vínculo
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await FirebaseFirestore.instance.collection('avisos').add({
                      'titulo': titulo,
                      'mensagem': mensagem,
                      'data': FieldValue.serverTimestamp(), // melhor que DateTime.now()
                      'lidoPor': [],
                      'escolaId': escolaId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                  if (context.mounted) Navigator.pop(context);
                } on FirebaseException catch (e) {
                  // Se aparecer "FAILED_PRECONDITION", falta índice composto (where+orderBy)
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
