import 'package:FamiliaEscolaApp/pages/forumThreadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forumThreadPage.dart';

class ForumPage extends StatelessWidget {
  final String escolaId;
  const ForumPage({super.key, required this.escolaId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fórum da Escola"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("escolas")
            .doc(escolaId)
            .collection("forum")
            .orderBy("criadoEm", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum tópico criado ainda"));
          }

          final topicos = snapshot.data!.docs;
          return ListView.builder(
            itemCount: topicos.length,
            itemBuilder: (context, index) {
              final data = topicos[index].data() as Map<String, dynamic>;

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(data['titulo'] ?? 'Sem título'),
                  subtitle: Text(
                    data['conteudo'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (uid != null)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid)
                              .snapshots(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const SizedBox.shrink();
                            }
                            final userData = userSnap.data!.data()
                            as Map<String, dynamic>? ??
                                {};
                            final role = userData['role'] ?? 'responsavel';

                            final podeEditar = (role == 'gestao' ||
                                data['autorId'] == uid);

                            if (!podeEditar) {
                              return const SizedBox.shrink();
                            }

                            return PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await FirebaseFirestore.instance
                                      .collection("escolas")
                                      .doc(escolaId)
                                      .collection("forum")
                                      .doc(topicos[index].id)
                                      .delete();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      SizedBox(width: 6),
                                      Text("Deletar",
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForumThreadPage(
                          escolaId: escolaId,
                          topicoId: topicos[index].id,
                          topicoData: data,
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
        onPressed: () => _criarTopico(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _criarTopico(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Novo Tópico"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: "Título")),
              TextField(
                  controller: conteudoCtrl,
                  decoration: const InputDecoration(labelText: "Mensagem")),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (uid == null) return;
                final userDoc = await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .get();
                final userData = userDoc.data() ?? {};

                await FirebaseFirestore.instance
                    .collection("escolas")
                    .doc(escolaId)
                    .collection("forum")
                    .add({
                  "titulo": tituloCtrl.text,
                  "conteudo": conteudoCtrl.text,
                  "autorId": uid,
                  "autorNome": userData['nome'] ?? 'Usuário',
                  "criadoEm": FieldValue.serverTimestamp(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Criar"),
            ),
          ],
        );
      },
    );
  }
}
