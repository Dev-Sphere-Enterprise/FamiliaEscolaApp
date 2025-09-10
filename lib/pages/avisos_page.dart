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
      body: Column(
        children: [
          AppBar(
            title: const Text(
              "Avisos da Escola",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF00A74F),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: avisosQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erro: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          "Nenhum aviso disponível",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                final avisos = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: avisos.length,
                  itemBuilder: (context, i) {
                    final doc = avisos[i];
                    final aviso = doc.data();
                    final lidoPor = List<String>.from(aviso['lidoPor'] ?? []);
                    final jaLido = lidoPor.contains(uid);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AvisoDetalhesPage(
                              avisoId: doc.id,
                              aviso: aviso,
                              role: role,
                              uid: uid,
                              jaLido: jaLido,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: jaLido
                              ? Colors.grey.shade50
                              : Colors.blue.shade50.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: jaLido
                                ? Colors.grey.shade300
                                : Colors.blue.shade300,
                          ),
                          boxShadow: [
                            if (!jaLido)
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (aviso['titulo'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                jaLido ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 18,
                                color: jaLido
                                    ? Colors.black87
                                    : Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (aviso['mensagem'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _fmtData(aviso['data'] as Timestamp?),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                                const Spacer(),
                                if (role == 'gestao')
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${lidoPor.length} leram",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                if (role == 'responsavel')
                                  Icon(
                                    jaLido
                                        ? Icons.check_circle
                                        : Icons.mark_email_unread,
                                    size: 18,
                                    color: jaLido ? Colors.green : Colors.red,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: role == 'gestao'
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarAvisoPage()),
          );
        },
        label: const Text("Novo Aviso"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00A74F),
      )
          : null,
    );
  }
}

class AvisoDetalhesPage extends StatelessWidget {
  final String avisoId;
  final Map<String, dynamic> aviso;
  final String role;
  final String uid;
  final bool jaLido;

  const AvisoDetalhesPage({
    super.key,
    required this.avisoId,
    required this.aviso,
    required this.role,
    required this.uid,
    required this.jaLido,
  });

  String _fmtData(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)}/${dt.year} ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  Future<void> _marcarComoLido() async {
    if (role == 'responsavel' && !jaLido) {
      await FirebaseFirestore.instance.collection('avisos').doc(avisoId).update({
        'lidoPor': FieldValue.arrayUnion([uid])
      });
    }
  }

  Future<void> _excluirAviso(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Aviso"),
        content: const Text("Tem certeza que deseja excluir este aviso?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('avisos').doc(avisoId).delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _marcarComoLido();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Aviso"),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (role == 'gestao') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: "Editar",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdicionarAvisoPage(avisoId: avisoId, aviso: aviso),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Excluir",
              onPressed: () => _excluirAviso(context),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aviso['titulo'] ?? 'Sem título',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _fmtData(aviso['data'] as Timestamp?),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                aviso['mensagem'] ?? 'Sem mensagem',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
