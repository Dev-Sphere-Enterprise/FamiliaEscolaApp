import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class MensagensPage extends StatelessWidget {
  const MensagensPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MainScaffold(
      currentIndex: 3, // ✅ Mensagens
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mensagens')
            .where('participantes', arrayContains: uid)
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
                title: Text(dados['titulo'] ?? 'Sem título'),
                subtitle: Text(
                  "Participantes: ${(dados['participantes'] as List).join(', ')}",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MensagensThreadPage(threadId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class MensagensThreadPage extends StatelessWidget {
  final String threadId;

  const MensagensThreadPage({super.key, required this.threadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conversa")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mensagens')
            .doc(threadId)
            .collection('itens')
            .orderBy('data', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma mensagem"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final dados = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(dados['autor'] ?? 'Anônimo'),
                subtitle: Text(dados['conteudo'] ?? ''),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
