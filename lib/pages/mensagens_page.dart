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

  /// Deleta uma conversa e todas as suas mensagens
  Future<void> _deletarConversa({
    required String escolaId,
    required String conversaId,
    required BuildContext context,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final conversaRef = FirebaseFirestore.instance
          .collection('escolas')
          .doc(escolaId)
          .collection('conversas')
          .doc(conversaId);

      // Primeiro verifica se o usuário é participante da conversa
      final conversaDoc = await conversaRef.get();
      if (!conversaDoc.exists) return;

      final participantes = List<String>.from(conversaDoc['participantes'] ?? []);
      if (!participantes.contains(uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você não tem permissão para deletar esta conversa.')),
        );
        return;
      }

      // Mostra diálogo de confirmação
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deletar conversa'),
          content: const Text('Tem certeza que deseja deletar esta conversa? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Deleta todas as mensagens primeiro
      final mensagensSnapshot = await conversaRef.collection('mensagens').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in mensagensSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Deleta a conversa
      await conversaRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversa deletada com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar conversa: $e')),
      );
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Conversas",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_comment, size: 22, color: Colors.white),
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
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                        ),
                      );
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
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role == 'gestao'
                                    ? 'Inicie uma conversa com um responsável'
                                    : 'Entre em contato com a escola',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFA0AEC0),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: minhasNaoLidas > 0
                                ? const Color(0xFFEBF4FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFF4F46E5),
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (dados['titulo'] ?? 'Conversa').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: minhasNaoLidas > 0 ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFF2D3748),
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA0AEC0),
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
                                  color: minhasNaoLidas > 0
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF718096),
                                  fontWeight: minhasNaoLidas > 0 ? FontWeight.w500 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (minhasNaoLidas > 0)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE53E3E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        minhasNaoLidas > 9 ? '9+' : '$minhasNaoLidas',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _deletarConversa(
                                        escolaId: escolaId,
                                        conversaId: doc.id,
                                        context: context,
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Deletar conversa', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MensagensThreadPage(escolaId: escolaId, conversaId: doc.id),
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4F46E5)),
            onSelected: (value) {
              if (value == 'delete') {
                _deletarConversa(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Deletar conversa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                    ),
                  );
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: const Color(0xFF4F46E5)
                              ),
                            ),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    ),
                                  if (!isMe) const SizedBox(height: 4),
                                  Text(
                                    conteudo,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : const Color(0xFF2D3748),
                                      fontSize: 15,
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
                                          color: isMe ? Colors.white70 : const Color(0xFFA0AEC0),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
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

  // Função para deletar conversa a partir da página de thread
  Future<void> _deletarConversa(BuildContext context) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final conversaRef = FirebaseFirestore.instance
          .collection('escolas')
          .doc(widget.escolaId)
          .collection('conversas')
          .doc(widget.conversaId);

      // Primeiro verifica se o usuário é participante da conversa
      final conversaDoc = await conversaRef.get();
      if (!conversaDoc.exists) return;

      final participantes = List<String>.from(conversaDoc['participantes'] ?? []);
      if (!participantes.contains(uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você não tem permissão para deletar esta conversa.')),
        );
        return;
      }

      // Mostra diálogo de confirmação
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deletar conversa'),
          content: const Text('Tem certeza que deseja deletar esta conversa? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Deleta todas as mensagens primeiro
      final mensagensSnapshot = await conversaRef.collection('mensagens').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in mensagensSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Deleta a conversa
      await conversaRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversa deletada com sucesso.')),
      );

      // Volta para a página anterior
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar conversa: $e')),
      );
    }
  }
}