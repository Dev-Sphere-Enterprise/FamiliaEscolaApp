import 'package:FamiliaEscolaApp/pages/alunos_page.dart';
import 'package:FamiliaEscolaApp/pages/mensagens_page.dart';
import 'package:FamiliaEscolaApp/pages/turmas_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../widgets/main_scaffold.dart';
import 'add_student_page.dart';
import 'avisos_page.dart';
import 'responsaveis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    final fcm = FirebaseMessaging.instance;

    // Solicita permissão (iOS)
    await fcm.requestPermission();

    // Obtém o token para debug
    final token = await fcm.getToken();
    print("🔥 Token FCM: $token");

    // Listener para foreground
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      if (notification != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.title ?? "Nova notificação")),
        );
      }
    });

    // Listener para clique em notificação
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = msg.data;
      if (data.containsKey("screen")) {
        if (data["screen"] == "avisos") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosPage()));
        } else if (data["screen"] == "chat" && data["conversaId"] != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MensagensThreadPage(
              escolaId: data["escolaId"],
              conversaId: data["conversaId"],
            ),
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = user.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final dados = snapshot.data!.data() as Map<String, dynamic>;
        final nomeUsuario = dados['nome'] ?? 'Usuário';
        final tipoPerfil = dados['role'] ?? 'responsavel';
        final isGestor = tipoPerfil == 'gestao';
        final escolaId = dados['escolaId'];

        if (escolaId == null) {
          return const Scaffold(body: Center(child: Text("Usuário não vinculado a uma escola")));
        }

        // 🔔 Inscreve nos tópicos da escola
        FirebaseMessaging.instance.subscribeToTopic("escola_$escolaId");

        return MainScaffold(
          currentIndex: 2,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Olá, $nomeUsuario!",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔔 Quadro de Avisos (4 mais recentes da escola)
                Flexible(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('avisos')
                        .where('escolaId', isEqualTo: escolaId) // 🔎 só da escola
                        .orderBy('data', descending: true)
                        .limit(4)
                        .snapshots(),
                    builder: (context, avisoSnapshot) {
                      if (avisoSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!avisoSnapshot.hasData ||
                          avisoSnapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("Nenhum aviso disponível"));
                      }

                      final avisos = avisoSnapshot.data!.docs;

                      // 🔎 contar não lidos (só para responsável)
                      int naoLidos = 0;
                      if (tipoPerfil == 'responsavel') {
                        for (var aviso in avisos) {
                          final data = aviso.data() as Map<String, dynamic>;
                          final lidoPor =
                          List<String>.from(data['lidoPor'] ?? []);
                          if (!lidoPor.contains(uid)) {
                            naoLidos++;
                          }
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Quadro de Avisos",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (tipoPerfil == 'responsavel' &&
                                    naoLidos > 0)
                                  Text(
                                    "🔴 $naoLidos novos",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Expanded(
                              child: ListView.builder(
                                itemCount: avisos.length,
                                itemBuilder: (context, index) {
                                  final aviso = avisos[index].data()
                                  as Map<String, dynamic>;
                                  final titulo =
                                      aviso['titulo'] ?? "Sem título";
                                  final mensagem = aviso['mensagem'] ?? "";
                                  final data =
                                  (aviso['data'] as Timestamp?)?.toDate();

                                  bool jaLido = true;
                                  if (tipoPerfil == 'responsavel') {
                                    final lidoPor = List<String>.from(
                                        aviso['lidoPor'] ?? []);
                                    jaLido = lidoPor.contains(uid);
                                  }

                                  return Card(
                                    color: (tipoPerfil == 'responsavel')
                                        ? (jaLido
                                        ? Colors.white
                                        : Colors.amber[100])
                                        : Colors.white,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        titulo,
                                        style: TextStyle(
                                          fontWeight: (tipoPerfil ==
                                              'responsavel' &&
                                              !jaLido)
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mensagem,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (data != null)
                                            Text(
                                              "${data.day}/${data.month}/${data.year}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AvisosPage(),
                                    ),
                                  );
                                },
                                child: const Text("Ver todos"),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),

                // 🔘 Botões de Atalho
                Center(
                  child: Wrap(
                    spacing: 35,
                    runSpacing: 25,
                    children: [
                      _menuButton("Alunos", Icons.people, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AlunosPage(),
                          ),
                        );
                      }),
                      _menuButton("Escola", Icons.school, () {}),
                      _menuButton("Turmas", Icons.class_, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TurmasPage(),
                          ),
                        );
                      }),
                      _menuButton("Chat", Icons.chat, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MensagensPage(),
                          ),
                        );
                      }),
                      if (isGestor)
                        _menuButton("Adicionar Aluno", Icons.person_add, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const AddStudentPage(),
                            ),
                          );
                        }),
                      if (isGestor)
                        _menuButton("Responsáveis", Icons.supervised_user_circle, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResponsaveisPage(
                                escolaId: escolaId,
                                gestorUid: uid, // passa UID do gestor logado
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 160,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}