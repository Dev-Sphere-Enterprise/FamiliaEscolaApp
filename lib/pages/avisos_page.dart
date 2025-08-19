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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Usuário não encontrado")),
          );
        }

        final role = (userSnapshot.data!.data() as Map<String, dynamic>)['role'] ?? 'responsavel';

        return MainScaffold(
          currentIndex: 1,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('avisos')
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
                  final aviso = doc.data() as Map<String, dynamic>;
                  final lido = (aviso['lidoPor'] as List?)?.contains(uid) ?? false;

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
                          : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showNovoAvisoDialog(
                              context,
                              isEdit: true,
                              docId: doc.id,
                              dados: aviso,
                            );
                          } else if (value == 'delete') {
                            FirebaseFirestore.instance
                                .collection('avisos')
                                .doc(doc.id)
                                .delete();
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text("Editar"),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text("Excluir"),
                          ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdicionarAvisoPage()),
              );
            },
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
    );
  }

  void _showNovoAvisoDialog(BuildContext context,
      {bool isEdit = false, String? docId, Map<String, dynamic>? dados}) {
    final tituloCtrl = TextEditingController(text: dados?['titulo'] ?? '');
    final mensagemCtrl = TextEditingController(text: dados?['mensagem'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEdit && docId != null) {
                FirebaseFirestore.instance.collection('avisos').doc(docId).update({
                  'titulo': tituloCtrl.text,
                  'mensagem': mensagemCtrl.text,
                });
              } else {
                FirebaseFirestore.instance.collection('avisos').add({
                  'titulo': tituloCtrl.text,
                  'mensagem': mensagemCtrl.text,
                  'data': DateTime.now(),
                  'lidoPor': [],
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}
