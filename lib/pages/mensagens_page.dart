import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

    // pega dados do próprio usuário (sempre permitido)
    final meData = (await FirebaseFirestore.instance
        .collection('users')
        .doc(meUid)
        .get())
        .data() ?? {};

    Map<String, dynamic> otherData = {};

    // só tenta buscar o outro se for gestor (tem permissão)
    final meuRole = meData['role'] ?? '';
    if (meuRole == 'gestao') {
      otherData = (await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get())
          .data() ?? {};
    }

    final otherNome = otherData['nome'] ?? 'Gestão';
    final otherRole = otherData['role'] ?? 'gestao';

    await conversaRef.set({
      'escolaId': escolaId,
      'tipo': '1-1',
      'participantes': [meUid, otherUid],
      'participantesInfo': {
        meUid: {'nome': meData['nome'] ?? 'Você', 'role': meuRole},
        otherUid: {'nome': otherNome, 'role': otherRole},
      },
      'titulo': otherNome,
      'ultimoTexto': '',
      'atualizadoEm': FieldValue.serverTimestamp(),
      'unread': {meUid: 0, otherUid: 0},
    }, SetOptions(merge: true));

    return conversaRef.id;
  }

  /// Para RESPONSÁVEL: encontra o gestor da escola e abre/cria o chat 1–1.
  /// Para RESPONSÁVEL: encontra o gestor da escola (direto no doc da escola)
  /// e abre/cria o chat 1–1.
  Future<void> _startChatWithGestor(
      BuildContext context, {
        required String escolaId,
        required String myUid,
      }) async {
    try {
      // Lê o doc da escola e pega o gestorId
      final escolaDoc = await FirebaseFirestore.instance
          .collection('escolas')
          .doc(escolaId)
          .get();

      final gestorId = escolaDoc.data()?['gestorId'] as String?;
      if (gestorId == null || gestorId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Escola sem gestor vinculado.')),
          );
        }
        return;
      }

      // Usa gestorId para abrir ou criar conversa
      final conversaId = await _openOrCreate1to1(
        escolaId: escolaId,
        meUid: myUid,
        otherUid: gestorId,
      );

      // Navega para a thread
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MensagensThreadPage(
              escolaId: escolaId,
              conversaId: conversaId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar conversa: $e')),
        );
      }
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
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Conversas",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment, size: 28),
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
              ),

              // Lista de conversas
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: conversasStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Estado vazio com CTA
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Nenhuma conversa",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role == 'gestao'
                                    ? 'Inicie uma conversa com um responsável'
                                    : 'Entre em contato com a escola',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
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
                                child: Text(role == 'gestao' ? 'Nova conversa' : 'Conversar com a escola'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Lista de conversas
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final dados = doc.data() as Map<String, dynamic>;
                        final ultimoTexto = (dados['ultimoTexto'] ?? '').toString();
                        final unreadMap = Map<String, dynamic>.from(dados['unread'] ?? {});
                        final int minhasNaoLidas = (unreadMap[uid] is int) ? unreadMap[uid] as int : 0;
                        final atualizadoEm = (dados['atualizadoEm'] as Timestamp?)?.toDate();
                        final timeStr = atualizadoEm != null
                            ? DateFormat.Hm().format(atualizadoEm)
                            : '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.indigo),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (dados['titulo'] ?? 'Conversa').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: minhasNaoLidas > 0 ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              ultimoTexto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: minhasNaoLidas > 0 ? Colors.indigo : Colors.grey[600],
                                fontWeight: minhasNaoLidas > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                          trailing: minhasNaoLidas > 0
                              ? Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$minhasNaoLidas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MensagensThreadPage(escolaId: escolaId, conversaId: doc.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
  final _scrollController = ScrollController();
  bool _marcouLidasNaAbertura = false;

  @override
  void initState() {
    super.initState();
    _marcarConversaComoLida();
    // Scroll para o final quando as mensagens carregarem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    // Scroll para o final após enviar mensagem
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conversa",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
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
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final data = mensagens[index].data() as Map<String, dynamic>;
                    final autorId = (data["autorId"] ?? '') as String;
                    final autorNome = (data["autorNome"] ?? "Anônimo").toString();
                    final conteudo = (data["conteudo"] ?? "").toString();
                    final timestamp = (data["data"] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null
                        ? DateFormat.Hm().format(timestamp)
                        : '';
                    final lidoPor = List<String>.from(data['lidoPor'] ?? []);
                    final isMe = autorId == uid;
                    final outrosLeram = lidoPor.any((x) => x != autorId);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.indigo[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 20, color: Colors.indigo),
                            ),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.indigo
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      autorNome,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.indigo[700],
                                      ),
                                    ),
                                  if (!isMe) const SizedBox(height: 4),
                                  Text(
                                    conteudo,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                      if (isMe)
                                        const SizedBox(width: 4),
                                      if (isMe && outrosLeram)
                                        const Icon(Icons.done_all, size: 14, color: Colors.white70),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: "Digite sua mensagem...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviarMensagem,
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