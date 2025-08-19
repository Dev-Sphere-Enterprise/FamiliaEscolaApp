import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MainScaffold(
      currentIndex: 1, // ✅ Avisos

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('avisosUsuarios')
            .doc(uid)
            .collection('itens')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum aviso disponível"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final dados = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(dados['titulo'] ?? ''),
                  subtitle: Text(dados['mensagem'] ?? ''),
                  trailing: dados['lido'] == true
                      ? const Icon(Icons.check, color: Colors.green)
                      : const Icon(Icons.mark_email_unread, color: Colors.red),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
