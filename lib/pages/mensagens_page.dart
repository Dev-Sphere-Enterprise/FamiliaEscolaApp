import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';
import 'selecionar_responsavel_page.dart';

class MensagensPage extends StatelessWidget {
  const MensagensPage({super.key});

  // ===== Helpers =====

  /// Cria um ID determinístico para chat 1-1 (ordena UIDs e junta com "_")
  String _pairKey(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Abre (ou cria) uma conversa 1-1 entre [meUid] e [otherUid].
  /// Retorna o conversaId.
  Future<String> _openOrCreate1to1({
    required String escolaId,
    required String meUid,
    required String otherUid,
  }) async {
    final pairId = _pairKey(meUid, otherUid);
    final conversaRef = FirebaseFirestore.instance
        .collection('escolas')
        .doc(escolaId)
        .collection('conversas')
        .doc(pairId);

    // pega dados dos usuários (para preencher info básica)
    final meData = (await FirebaseFirestore.instance.collection('users').doc(meUid).get()).data() ?? {};
    final otherData = (await FirebaseFirestore.instance.collection('users').doc(otherUid).get()).data() ?? {};

    await conversaRef.set({
      'escolaId': escolaId,
      'tipo': '1-1',
      'participantes': [meUid, otherUid],
      'participantesInfo': {
        meUid: {'nome': meData['nome'] ?? 'Você', 'role': meData['role'] ?? ''},
        otherUid: {'nome': otherData['nome'] ?? 'Contato', 'role': otherData['role'] ?? ''},
      },
      'titulo': otherData['nome'] ?? 'Conversa',
      'ultimoTexto': '',
      'atualizadoEm': FieldValue.serverTimestamp(),
      'unread': {meUid: 0, otherUid: 0},
    }, SetOptions(merge: true)); // 🔑 evita precisar de get()

    return conversaRef.id;
  }

  /// Para RESPONSÁVEL: encontra o gestor da escola e abre/cria o chat 1–1.
  Future<void> _startChatWithGestor(BuildContext context, {
    required String escolaId,
    required String myUid,
  }) async {
    final escola = await FirebaseFirestore.instance.collection('escolas').doc(escolaId).get();
    final gestorId = escola.data()?['gestorId'] as String?;
    if (gestorId == null || gestorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escola sem gestor vinculado.')));
      return;
    }

    final conversaId = await _openOrCreate1to1(escolaId: escolaId, meUid: myUid, otherUid: gestorId);

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MensagensThreadPage(escolaId: escolaId, conversaId: conversaId),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Usuário não autenticado")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null || !userData.containsKey("escolaId")) {
          return const Scaffold(body: Center(child: Text("Usuário não vinculado a uma escola")));
        }

        final escolaId = userData["escolaId"] as String;
        final role = (userData["role"] ?? "responsavel") as String;

        final conversasStream = FirebaseFirestore.instance
            .collection("escolas").doc(escolaId)
            .collection("conversas")
            .where("participantes", arrayContains: uid)
            .orderBy("atualizadoEm", descending: true)
            .snapshots();

        return MainScaffold(
          currentIndex: 3,
          body: StreamBuilder<QuerySnapshot>(
            stream: conversasStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Estado vazio com CTA
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Nenhuma conversa encontrada"),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: Text(role == 'gestao'
                            ? 'Nova conversa (responsável)'
                            : 'Conversar com a escola'),
                        onPressed: () async {
                          if (role == 'gestao') {
                            // abre a lista de responsáveis
                            final selected = await Navigator.push<Map<String, dynamic>?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SelecionarResponsavelPage(escolaId: escolaId),
                              ),
                            );
                            if (selected != null && selected['uid'] != null) {
                              final conversaId = await _openOrCreate1to1(
                                escolaId: escolaId,
                                meUid: uid,
                                otherUid: selected['uid'] as String,
                              );
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MensagensThreadPage(
                                        escolaId: escolaId, conversaId: conversaId),
                                  ),
                                );
                              }
                            }
                          } else {
                            await _startChatWithGestor(context, escolaId: escolaId, myUid: uid);
                          }
                        },
                      ),
                    ],
                  ),
                );
              }

              // Lista de conversas
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final ultimoTexto = (dados['ultimoTexto'] ?? '').toString();
                  final unreadMap = Map<String, dynamic>.from(dados['unread'] ?? {});
                  final int minhasNaoLidas = (unreadMap[uid] is int) ? unreadMap[uid] as int : 0;

                  return ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(
                      (dados['titulo'] ?? 'Conversa').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: minhasNaoLidas > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(ultimoTexto, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: minhasNaoLidas > 0
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      child: Text('$minhasNaoLidas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                        : const SizedBox.shrink(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MensagensThreadPage(escolaId: escolaId, conversaId: doc.id),
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
  bool _marcouLidasNaAbertura = false;

  @override
  void initState() {
    super.initState();
    _marcarConversaComoLida();
  }

  Future<void> _marcarConversaComoLida() async {
    if (_marcouLidasNaAbertura) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final conversaRef = FirebaseFirestore.instance
        .collection("escolas").doc(widget.escolaId)
        .collection("conversas").doc(widget.conversaId);

    try {
      await conversaRef.update({"unread.$uid": 0});
      final msgs = await conversaRef.collection("mensagens")
          .orderBy("data", descending: true).limit(50).get();

      final batch = FirebaseFirestore.instance.batch();
      for (final m in msgs.docs) {
        final data = m.data() as Map<String, dynamic>;
        final lidoPor = List<String>.from(data['lidoPor'] ?? []);
        if (!lidoPor.contains(uid)) {
          batch.update(m.reference, {'lidoPor': FieldValue.arrayUnion([uid])});
        }
      }
      await batch.commit();
    } catch (_) {} finally {
      _marcouLidasNaAbertura = true;
    }
  }

  Future<void> _marcarMensagensVisiveisComoLidas(List<QueryDocumentSnapshot> docs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs.take(50)) {
      final data = d.data() as Map<String, dynamic>;
      final lidoPor = List<String>.from(data['lidoPor'] ?? []);
      if (!lidoPor.contains(uid)) {
        batch.update(d.reference, {'lidoPor': FieldValue.arrayUnion([uid])});
      }
    }
    try { await batch.commit(); } catch (_) {}
  }

  Future<void> _enviarMensagem() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _msgCtrl.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final userData = userDoc.data() ?? {};
    final conversaRef = FirebaseFirestore.instance
        .collection("escolas").doc(widget.escolaId)
        .collection("conversas").doc(widget.conversaId);

    final conteudo = _msgCtrl.text.trim();

    // 1) cria a mensagem
    final msgRef = conversaRef.collection("mensagens").doc();
    await msgRef.set({
      "autorId": uid,
      "autorNome": userData["nome"] ?? "Anônimo",
      "conteudo": conteudo,
      "tipo": "texto",
      "data": FieldValue.serverTimestamp(),
      "lidoPor": [uid], // autor já leu
    });

    // 2) atualiza conversa
    final convSnap = await conversaRef.get();
    final convData = (convSnap.data() ?? {}) as Map<String, dynamic>;
    final participantes = List<String>.from(convData['participantes'] ?? []);
    final unread = Map<String, dynamic>.from(convData['unread'] ?? {});

    for (final p in participantes) {
      if (p == uid) continue;
      unread[p] = (unread[p] is int ? unread[p] as int : 0) + 1;
    }

    await conversaRef.update({
      "ultimoTexto": conteudo,
      "atualizadoEm": FieldValue.serverTimestamp(),
      "unread": unread,
    });

    _msgCtrl.clear();
  }


  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Conversa")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("escolas").doc(widget.escolaId)
                  .collection("conversas").doc(widget.conversaId)
                  .collection("mensagens")
                  .orderBy("data", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mensagens = snapshot.data!.docs;
                _marcarMensagensVisiveisComoLidas(mensagens.cast<QueryDocumentSnapshot>());

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final data = mensagens[index].data() as Map<String, dynamic>;
                    final autorId = (data["autorId"] ?? '') as String;
                    final autorNome = (data["autorNome"] ?? "Anônimo").toString();
                    final conteudo = (data["conteudo"] ?? "").toString();
                    final lidoPor = List<String>.from(data['lidoPor'] ?? []);
                    final isMe = autorId == uid;
                    final outrosLeram = lidoPor.any((x) => x != autorId);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade50 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(autorNome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(conteudo),
                            const SizedBox(height: 6),
                            if (isMe && outrosLeram)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.done_all, size: 14, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text("Lida", style: TextStyle(fontSize: 11, color: Colors.blue)),
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
          SafeArea(
            top: false,
            child: Padding(
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
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(icon: const Icon(Icons.send), onPressed: _enviarMensagem),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
