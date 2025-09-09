import 'package:FamiliaEscolaApp/pages/adicionar_avisos_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  String _fmtData(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)} ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!userSnapshot.hasData || !(userSnapshot.data?.exists ?? false)) {
          return const Scaffold(body: Center(child: Text("Usuário não encontrado")));
        }

        final userData = userSnapshot.data!.data() ?? {};
        final role = (userData['role'] ?? 'responsavel') as String;
        final escolaId = userData['escolaId'] as String?;

        if (escolaId == null || escolaId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Usuário não vinculado a nenhuma escola.")),
          );
        }

        final avisosQuery = FirebaseFirestore.instance
            .collection('avisos')
            .where('escolaId', isEqualTo: escolaId)
            .orderBy('data', descending: true);

        return _ScaffoldAvisos(
          role: role,
          uid: uid,
          avisosQuery: avisosQuery,
        );
      },
    );
  }
}

class _ScaffoldAvisos extends StatelessWidget {
  final String role;
  final String uid;
  final Query<Map<String, dynamic>> avisosQuery;

  const _ScaffoldAvisos({
    required this.role,
    required this.uid,
    required this.avisosQuery,
  });

  String _fmtData(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)} ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: avisosQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum aviso disponível"));
          }

          final avisos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: avisos.length,
            itemBuilder: (context, i) {
              final doc = avisos[i];
              final aviso = doc.data();
              final lidoPor = List<String>.from(aviso['lidoPor'] ?? []);
              final jaLido = lidoPor.contains(uid);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: jaLido ? Colors.grey.shade300 : Colors.blue.shade300,
                    width: 1.5,
                  ),
                  color: Colors.white,
                  boxShadow: [
                    if (!jaLido)
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.campaign, color: Colors.blue),
                  ),
                  title: Text(
                    (aviso['titulo'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: jaLido ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 16,
                      color: jaLido ? Colors.black87 : Colors.blue.shade700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        (aviso['mensagem'] ?? '').toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          height: 1.3,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _fmtData(aviso['data'] as Timestamp?),
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const Spacer(),
                          if (role == 'gestao')
                            Row(
                              children: [
                                const Icon(Icons.visibility, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  "${lidoPor.length} leram",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: role == 'responsavel'
                      ? IconButton(
                    icon: Icon(
                      jaLido ? Icons.check_circle : Icons.mark_email_unread,
                      color: jaLido ? Colors.green : Colors.red,
                    ),
                    tooltip: jaLido ? "Aviso já lido" : "Marcar como lido",
                    onPressed: jaLido
                        ? null
                        : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('avisos')
                            .doc(doc.id)
                            .update({
                          'lidoPor': FieldValue.arrayUnion([uid])
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erro: $e")),
                        );
                      }
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: role == 'gestao'
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarAvisoPage()),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

