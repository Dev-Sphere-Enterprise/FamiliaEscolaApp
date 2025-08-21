import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class MensagensPage extends StatelessWidget {
  const MensagensPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null || !userData.containsKey("escolaId")) {
          return const Scaffold(
            body: Center(child: Text("Usuário não vinculado a uma escola")),
          );
        }

        final escolaId = userData["escolaId"];

        return MainScaffold(
          currentIndex: 3,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("escolas")
                .doc(escolaId)
                .collection("conversas")
                .where("participantes", arrayContains: uid)
                .orderBy("atualizadoEm", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Nenhuma conversa encontrada"));
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(dados['titulo'] ?? 'Conversa sem título'),
                    subtitle: Text(dados['ultimoTexto'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MensagensThreadPage(
                            escolaId: escolaId,
                            conversaId: doc.id,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class MensagensThreadPage extends StatefulWidget {
  final String escolaId;
  final String conversaId;

  const MensagensThreadPage({
    super.key,
    required this.escolaId,
    required this.conversaId,
  });

  @override
  State<MensagensThreadPage> createState() => _MensagensThreadPageState();
}

class _MensagensThreadPageState extends State<MensagensThreadPage> {
  final _msgCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _enviarMensagem() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _msgCtrl.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final userData = userDoc.data() ?? {};

    final mensagem = {
      "autorId": uid,
      "autorNome": userData["name"] ?? "Anônimo",
      "conteudo": _msgCtrl.text.trim(),
      "data": FieldValue.serverTimestamp(),
    };

    final conversaRef = FirebaseFirestore.instance
        .collection("escolas")
        .doc(widget.escolaId)
        .collection("conversas")
        .doc(widget.conversaId);

    await conversaRef.collection("mensagens").add(mensagem);

    // Atualiza info da conversa
    await conversaRef.update({
      "ultimoTexto": mensagem["conteudo"],
      "atualizadoEm": FieldValue.serverTimestamp(),
    });

    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conversa")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("escolas")
                  .doc(widget.escolaId)
                  .collection("conversas")
                  .doc(widget.conversaId)
                  .collection("mensagens")
                  .orderBy("data", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mensagens = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(msg["autorNome"] ?? "Anônimo"),
                      subtitle: Text(msg["conteudo"] ?? ""),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
