import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/main_scaffold.dart';
import 'aluno_detalhes_page.dart';

class AlunosPage extends StatelessWidget {
  const AlunosPage({super.key});

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
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
              ),
            ),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text("Usuário não encontrado"),
            ),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'responsavel';
        final escolaIdUser = userData['escolaId'];
        final userName = userData['nome'] ?? 'Usuário';

        if (escolaIdUser == null || escolaIdUser.toString().isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Usuário não vinculado a uma escola"),
            ),
          );
        }

        // Query de alunos
        Query alunosQuery;
        if (role == 'gestao') {
          alunosQuery = FirebaseFirestore.instance
              .collection('students')
              .where('escolaId', isEqualTo: escolaIdUser)
              .orderBy('nome');
        } else {
          final cpfUsuario = userData['cpf']?.toString();
          if (cpfUsuario == null || cpfUsuario.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text("CPF do usuário não cadastrado"),
              ),
            );
          }

          alunosQuery = FirebaseFirestore.instance
              .collection('students')
              .where('escolaId', isEqualTo: escolaIdUser)
              .where('responsibleCpf', isEqualTo: cpfUsuario)
              .orderBy('nome');
        }

        return MainScaffold(
          currentIndex: 0,
          body: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Alunos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF00A74F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A74F).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt_outlined,
                          size: 24,
                          color: Color(0xFF00A74F),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role == 'gestao' ? 'Todos os Alunos' : 'Meus Alunos',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role == 'gestao'
                                  ? 'Escola ID: $escolaIdUser'
                                  : 'Alunos vinculados a $userName',
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de alunos
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: alunosQuery.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            "Erro ao carregar alunos",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                role == 'gestao'
                                    ? 'Nenhum aluno cadastrado'
                                    : 'Nenhum aluno vinculado',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role == 'gestao'
                                    ? 'ID da Escola: $escolaIdUser'
                                    : 'Verifique o CPF cadastrado',
                                style: const TextStyle(
                                  color: Color(0xFFA0AEC0),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final alunos = snapshot.data!.docs;

                      return Column(
                        children: [
                          // Contador de alunos
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: Colors.grey.shade50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ${alunos.length} aluno(s)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF00A74F),
                                  ),
                                ),
                                Text(
                                  'Escola ID: $escolaIdUser',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Lista
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemCount: alunos.length,
                              itemBuilder: (context, index) {
                                final alunoDoc = alunos[index];
                                final aluno = alunoDoc.data() as Map<String, dynamic>;

                                final alunoNome = aluno['nome'] ?? 'Sem nome';
                                final responsavelNome = aluno['responsibleName'] ?? 'Não informado';
                                final escolaIdAluno = aluno['escolaId'] ?? '';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A74F).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          alunoNome.isNotEmpty ? alunoNome[0].toUpperCase() : "?",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00A74F),
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      alunoNome,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "Responsável: $responsavelNome",
                                          style: const TextStyle(
                                            color: Color(0xFF718096),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          "Escola ID: $escolaIdAluno",
                                          style: const TextStyle(
                                            color: Color(0xFFA0AEC0),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A74F).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                          color: Color(0xFF00A74F),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AlunoDetalhesPage(
                                                alunoId: alunoDoc.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
