import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final criadoEm = (topico['criadoEm'] as Timestamp?)?.toDate();
    final formattedDate = criadoEm != null
        ? DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(criadoEm)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Discussão",
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
          // Post principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A74F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: Color(0xFF00A74F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topico['autorNome'] ?? 'Usuário',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  topico['titulo'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  topico['conteudo'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A5568),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Header Respostas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("escolas")
                  .doc(widget.escolaId)
                  .collection("forum")
                  .doc(widget.topicoId)
                  .collection("respostas")
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF718096)),
                    const SizedBox(width: 8),
                    Text(
                      "$count ${count == 1 ? 'resposta' : 'respostas'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                    ),
                  );
                }

                final respostas = snapshot.data!.docs;
                if (respostas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhuma resposta ainda",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Seja o primeiro a responder!",
                          style: TextStyle(
                            color: Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: respostas.length,
                  itemBuilder: (context, index) {
                    final data = respostas[index].data() as Map<String, dynamic>;
                    final respostaCriadoEm = (data['criadoEm'] as Timestamp?)?.toDate();
                    final respostaFormattedDate = respostaCriadoEm != null
                        ? DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(respostaCriadoEm)
                        : '';

                    final podeDeletar = _isLoadingUser
                        ? false
                        : (userRole == 'gestao' || data['autorId'] == uid);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A74F).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: Color(0xFF00A74F),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['autorNome'] ?? 'Usuário',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (respostaFormattedDate.isNotEmpty)
                              Text(
                                respostaFormattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data['conteudo'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: podeDeletar
                            ? PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
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
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Deletar", style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            )
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de resposta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _respostaCtrl,
                      decoration: const InputDecoration(
                        hintText: "Escreva uma resposta...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A74F),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _enviarResposta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}