import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forumThreadPage.dart';

class ForumPage extends StatelessWidget {
  final String escolaId;

  const ForumPage({
    super.key,
    required this.escolaId,
  });

  @override
  Widget build(BuildContext context) {
    final forumStream = FirebaseFirestore.instance
        .collection("escolas")
        .doc(escolaId)
        .collection("forum")
        .orderBy("criadoEm", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fórum da Escola"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: forumStream,
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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(data['titulo'] ?? 'Sem título'),
                  subtitle: Text(
                    data['conteudo'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        onPressed: () => _criarTopico(context, escolaId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _criarTopico(BuildContext context, String escolaId) {
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();

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
                decoration: const InputDecoration(labelText: "Título"),
              ),
              TextField(
                controller: conteudoCtrl,
                decoration: const InputDecoration(labelText: "Mensagem"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
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