import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForumThreadPage extends StatefulWidget {
  final String escolaId;
  final String topicoId;
  final Map<String, dynamic> topicoData;

  const ForumThreadPage({
    super.key,
    required this.escolaId,
    required this.topicoId,
    required this.topicoData,
  });

  @override
  State<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends State<ForumThreadPage> {
  final _respostaCtrl = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic> _userData = {};
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (uid == null) {
      setState(() {
        _isLoadingUser = false;
      });
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    setState(() {
      _userData = userDoc.data() ?? {};
      _isLoadingUser = false;
    });
  }

  Future<void> _enviarResposta() async {
    if (uid == null || _respostaCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("escolas")
        .doc(widget.escolaId)
        .collection("forum")
        .doc(widget.topicoId)
        .collection("respostas")
        .add({
      "conteudo": _respostaCtrl.text.trim(),
      "autorId": uid,
      "autorNome": _userData["nome"] ?? "Usuário",
      "criadoEm": FieldValue.serverTimestamp(),
    });

    _respostaCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final topico = widget.topicoData;
    final userRole = _userData['role'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(topico['titulo'] ?? "Tópico"),
      ),
      body: Column(
        children: [
          // Post principal
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topico['titulo'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(topico['conteudo'] ?? ''),
                const SizedBox(height: 8),
                Text(
                  "Por: ${topico['autorNome'] ?? 'Usuário'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de respostas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("escolas")
                  .doc(widget.escolaId)
                  .collection("forum")
                  .doc(widget.topicoId)
                  .collection("respostas")
                  .orderBy("criadoEm", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final respostas = snapshot.data!.docs;
                if (respostas.isEmpty) {
                  return const Center(child: Text("Nenhuma resposta ainda"));
                }

                return ListView.builder(
                  itemCount: respostas.length,
                  itemBuilder: (context, index) {
                    final data = respostas[index].data() as Map<String, dynamic>;

                    // Lógica otimizada para permissões
                    final podeDeletar = _isLoadingUser
                        ? false
                        : (userRole == 'gestao' || data['autorId'] == uid);

                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(data['conteudo'] ?? ''),
                      subtitle: Text("Por: ${data['autorNome'] ?? 'Usuário'}"),
                      trailing: podeDeletar
                          ? PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await FirebaseFirestore.instance
                                .collection("escolas")
                                .doc(widget.escolaId)
                                .collection("forum")
                                .doc(widget.topicoId)
                                .collection("respostas")
                                .doc(respostas[index].id)
                                .delete();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 6),
                                Text("Deletar", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          )
                        ],
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Campo de resposta
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _respostaCtrl,
                    decoration: const InputDecoration(
                      hintText: "Escreva uma resposta...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _enviarResposta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}