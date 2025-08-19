import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/main_scaffold.dart';
import 'add_student_page.dart';
import 'avisos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Dados do usuário não encontrados")),
          );
        }

        final dados = snapshot.data!.data() as Map<String, dynamic>;
        final nomeUsuario = dados['name'] ?? 'Usuário';
        final tipoPerfil = dados['role'] ?? 'responsavel';
        final isGestor = tipoPerfil == 'gestao';

        return MainScaffold(
          currentIndex: 2, // Home
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Olá, $nomeUsuario!",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔔 Quadro de Avisos (3 mais recentes)
                Flexible(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('avisos')
                        .orderBy('data', descending: true)
                        .limit(3)
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
                      final uid = FirebaseAuth.instance.currentUser?.uid;

                      // 🔎 contar não lidos (só se for responsável)
                      int naoLidos = 0;
                      if (tipoPerfil == 'responsavel') {
                        for (var aviso in avisos) {
                          final data =
                          aviso.data() as Map<String, dynamic>;
                          final lidoPor =
                          List<String>.from(data['lidoPor'] ?? []);
                          if (uid != null && !lidoPor.contains(uid)) {
                            naoLidos++;
                          }
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // fundo mais escuro
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔴 título + badge (só para responsável)
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

                            // lista resumida de avisos
                            Expanded(
                              child: ListView.builder(
                                itemCount: avisos.length,
                                itemBuilder: (context, index) {
                                  final aviso = avisos[index].data()
                                  as Map<String, dynamic>;
                                  final titulo =
                                      aviso['titulo'] ?? "Sem título";
                                  final mensagem =
                                      aviso['mensagem'] ?? "";
                                  final data =
                                  (aviso['data'] as Timestamp?)
                                      ?.toDate();

                                  // só marca cores/lido se for responsável
                                  bool jaLido = true;
                                  if (tipoPerfil == 'responsavel') {
                                    final lidoPor =
                                    List<String>.from(aviso['lidoPor'] ?? []);
                                    jaLido = uid != null &&
                                        lidoPor.contains(uid);
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
                                            overflow:
                                            TextOverflow.ellipsis,
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

                            // botão ver todos
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

                const SizedBox(height: 16),

                // 🔘 Botões de Atalho
                Center(
                  child: Wrap(
                    spacing: 35,
                    runSpacing: 25,
                    children: [
                      _menuButton("Alunos", Icons.people, () {}),
                      _menuButton("Escola", Icons.school, () {}),
                      _menuButton("Turmas", Icons.class_, () {}),
                      _menuButton("Chat", Icons.chat, () {}),
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
      width: 150,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}
