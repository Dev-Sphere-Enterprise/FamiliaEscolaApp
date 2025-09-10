import 'package:FamiliaEscolaApp/pages/alunos_page.dart';
import 'package:FamiliaEscolaApp/pages/mensagens_page.dart';
import 'package:FamiliaEscolaApp/pages/school_details_page.dart';
import 'package:FamiliaEscolaApp/pages/turmas_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

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
  String? _escolaId;

  // Helper: inscreve no tópico da escola (chamado a cada build, mas só executa se mudar)
  void _subscribeToSchoolTopic(String escolaId) {
    if (_escolaId != escolaId) {
      _escolaId = escolaId;
      FirebaseMessaging.instance.subscribeToTopic("escola_$escolaId");
      print("📱 Inscrito no tópico: escola_$escolaId");
    }
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
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
              ),
            ),
          );
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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Color(0xFFA0AEC0),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Usuário não vinculado a uma escola",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 🔔 Inscreve nos tópicos da escola (apenas 1 vez por usuário)
        _subscribeToSchoolTopic(escolaId);

        return MainScaffold(
          currentIndex: 2,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de boas-vindas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A74F).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 26,
                          color: const Color(0xFF00A74F),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Olá, $nomeUsuario!",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGestor ? "Perfil: Gestão Escolar" : "Perfil: Responsável",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔔 Quadro de Avisos
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('avisos')
                          .where('escolaId', isEqualTo: escolaId)
                          .orderBy('data', descending: true)
                          .limit(4)
                          .snapshots(),
                      builder: (context, avisoSnapshot) {
                        if (avisoSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(
                                  0xFF00A74F)),
                            ),
                          );
                        }

                        if (!avisoSnapshot.hasData || avisoSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.announcement_outlined,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Nenhum aviso disponível",
                                  style: TextStyle(
                                    color: Color(0xFFA0AEC0),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final avisos = avisoSnapshot.data!.docs;

                        // 🔎 contar não lidos (só para responsável)
                        int naoLidos = 0;
                        if (tipoPerfil == 'responsavel') {
                          for (var aviso in avisos) {
                            final data = aviso.data() as Map<String, dynamic>;
                            final lidoPor = List<String>.from(data['lidoPor'] ?? []);
                            if (!lidoPor.contains(uid)) {
                              naoLidos++;
                            }
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "📋 Quadro de Avisos",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                if (tipoPerfil == 'responsavel' && naoLidos > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "$naoLidos não lidos",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Expanded(
                              child: ListView.separated(
                                itemCount: avisos.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final aviso = avisos[index].data() as Map<String, dynamic>;
                                  final titulo = aviso['titulo'] ?? "Sem título";
                                  final mensagem = aviso['mensagem'] ?? "";
                                  final data = (aviso['data'] as Timestamp?)?.toDate();

                                  bool jaLido = true;
                                  if (tipoPerfil == 'responsavel') {
                                    final lidoPor = List<String>.from(aviso['lidoPor'] ?? []);
                                    jaLido = lidoPor.contains(uid);
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: (tipoPerfil == 'responsavel' && !jaLido)
                                          ? const Color(0xFFEBF4FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00A74F).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.campaign,
                                          size: 20,
                                          color: const Color(0xFF00A74F),
                                        ),
                                      ),
                                      title: Text(
                                        titulo,
                                        style: TextStyle(
                                          fontWeight: (tipoPerfil == 'responsavel' && !jaLido)
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: const Color(0xFF2D3748),
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            mensagem,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF718096),
                                            ),
                                          ),
                                          if (data != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                DateFormat('dd/MM/yyyy').format(data),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFA0AEC0),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: (tipoPerfil == 'responsavel' && !jaLido)
                                          ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AvisosPage()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00A74F),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Ver todos os avisos"),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔘 Botões de Atalho
                const Text(
                  "Atalhos Rápidos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  flex: 3,
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _menuButton("Alunos", Icons.people_outline, const Color(
                          0xFF00A74F), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlunosPage()),
                        );
                      }),
                      _menuButton("Turmas", Icons.class_outlined, const Color(
                          0xFF6B0000), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TurmasPage()),
                        );
                      }),
                      _menuButton("Mensagens", Icons.chat_outlined, const Color(0xFFED8936), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MensagensPage()),
                        );
                      }),
                      if (isGestor)
                        _menuButton("Adicionar Aluno", Icons.person_add_outlined, const Color(0xFF4299E1), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddStudentPage()),
                          );
                        }),
                      if (isGestor)
                        _menuButton("Responsáveis", Icons.supervised_user_circle_outlined, const Color(0xFF9F7AEA), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResponsaveisPage(
                                escolaId: escolaId,
                                gestorUid: uid,
                              ),
                            ),
                          );
                        }),
                      _menuButton("Escola", Icons.school_outlined, const Color(0xFFF56565), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolDetailsPage(schoolId: escolaId),
                          ),
                        );                        
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}