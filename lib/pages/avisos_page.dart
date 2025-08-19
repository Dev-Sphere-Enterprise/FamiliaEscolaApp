import 'package:FamiliaEscolaApp/widgets/main_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Usuário não autenticado")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'responsavel';

        return MainScaffold(
          currentIndex: 1, // Avisos
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('avisos')
                      .orderBy('data', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Nenhum aviso disponível"));
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        final aviso = doc.data() as Map<String, dynamic>;
                        final lido = (aviso['lidoPor'] ?? []).contains(uid);

                        return Card(
                          child: ListTile(
                            title: Text(aviso['titulo'] ?? ''),
                            subtitle: Text(aviso['mensagem'] ?? ''),
                            trailing: role == 'responsavel'
                                ? IconButton(
                              icon: Icon(
                                lido ? Icons.check_circle : Icons.mark_email_unread,
                                color: lido ? Colors.green : Colors.red,
                              ),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('avisos')
                                    .doc(doc.id)
                                    .update({
                                  'lidoPor': FieldValue.arrayUnion([uid])
                                });
                              },
                            )
                                : Icon(Icons.campaign, color: Colors.blue),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Só o gestor pode adicionar avisos
              if (role == 'gestao')
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showNovoAvisoDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Novo Aviso"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNovoAvisoDialog(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Novo Aviso"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: "Título")),
            TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: "Mensagem")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('avisos').add({
                'titulo': tituloCtrl.text,
                'mensagem': msgCtrl.text,
                'data': DateTime.now(),
                'lidoPor': [],
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}
