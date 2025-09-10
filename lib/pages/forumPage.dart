import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        title: const Text(
          "Fórum da Escola",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A74F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    size: 24,
                    color: Color(0xFF00A74F),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fórum de Discussão",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Compartilhe ideias e dúvidas com a comunidade",
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de tópicos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: forumStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhum tópico criado ainda",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Seja o primeiro a iniciar uma discussão!",
                          style: TextStyle(
                            color: Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final topicos = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: topicos.length,
                  itemBuilder: (context, index) {
                    final data = topicos[index].data() as Map<String, dynamic>;
                    final criadoEm = (data['criadoEm'] as Timestamp?)?.toDate();
                    final formattedDate = criadoEm != null
                        ? DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(criadoEm)
                        : '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A74F).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 24,
                            color: Color(0xFF00A74F),
                          ),
                        ),
                        title: Text(
                          data['titulo'] ?? 'Sem título',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['conteudo'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (formattedDate.isNotEmpty)
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                          ],
                        ),
                        trailing: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("escolas")
                              .doc(escolaId)
                              .collection("forum")
                              .doc(topicos[index].id)
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox();
                            final docData = snap.data!.data() as Map<String, dynamic>? ?? {};
                            final likes = List<String>.from(docData['likes'] ?? []);
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final isLiked = uid != null && likes.contains(uid);

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                    color: isLiked ? Colors.blue : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    if (uid == null) return;
                                    final ref = FirebaseFirestore.instance
                                        .collection("escolas")
                                        .doc(escolaId)
                                        .collection("forum")
                                        .doc(topicos[index].id);

                                    if (isLiked) {
                                      await ref.update({
                                        "likes": FieldValue.arrayRemove([uid])
                                      });
                                    } else {
                                      await ref.update({
                                        "likes": FieldValue.arrayUnion([uid])
                                      });
                                    }
                                  },
                                ),
                                Text("${likes.length}"),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF00A74F)),
                              ],
                            );
                          },
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _criarTopico(context, escolaId),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _criarTopico(BuildContext context, String escolaId) {
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Novo Tópico",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: tituloCtrl,
                  decoration: InputDecoration(
                    hintText: "Digite o título do tópico",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: conteudoCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Digite sua mensagem",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (tituloCtrl.text.isEmpty || conteudoCtrl.text.isEmpty) return;

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
                            "likes": [], // inicia vazio
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text("Criar Tópico"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
