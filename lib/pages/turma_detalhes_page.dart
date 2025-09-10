import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'TurmaRelatorioPage.dart';
import 'visualizar_relatorio_page.dart';

class TurmaDetalhesPage extends StatefulWidget {
  final String escolaId;
  final String turmaId;
  final String turmaNome;

  const TurmaDetalhesPage({
    super.key,
    required this.escolaId,
    required this.turmaId,
    required this.turmaNome,
  });

  @override
  State<TurmaDetalhesPage> createState() => _TurmaDetalhesPageState();
}

class _TurmaDetalhesPageState extends State<TurmaDetalhesPage> {
  Future<void> _matricularAluno(String studentId) async {
    try {
      final studentRef =
      FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({'turmaId': widget.turmaId});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aluno matriculado com sucesso!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao matricular aluno: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _desmatricularAluno(String studentId) async {
    try {
      final studentRef =
      FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({'turmaId': FieldValue.delete()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aluno desmatriculado com sucesso!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao desmatricular aluno: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Turma: ${widget.turmaNome}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .where('escolaId', isEqualTo: widget.escolaId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        "Erro ao carregar alunos",
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "Nenhum aluno encontrado nesta escola",
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allStudents = snapshot.data!.docs;
              final alunosMatriculados = allStudents
                  .where((doc) =>
              (doc.data() as Map<String, dynamic>)['turmaId'] ==
                  widget.turmaId)
                  .toList();
              final alunosDisponiveis = allStudents
                  .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !data.containsKey('turmaId') || data['turmaId'] == null;
              })
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alunos Matriculados
                  _buildSectionHeader(
                    icon: Icons.group,
                    title: "Alunos Matriculados",
                    count: alunosMatriculados.length,
                  ),
                  const SizedBox(height: 12),

                  if (alunosMatriculados.isEmpty)
                    _buildEmptyState(
                      icon: Icons.person_add,
                      message: "Nenhum aluno matriculado nesta turma",
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alunosMatriculados.length,
                    itemBuilder: (context, index) {
                      final studentDoc = alunosMatriculados[index];
                      final student = studentDoc.data() as Map<String, dynamic>;
                      return _buildStudentCard(
                        student: student,
                        isEnrolled: true,
                        onPressed: () => _desmatricularAluno(studentDoc.id),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 24),

                  // Alunos Disponíveis
                  _buildSectionHeader(
                    icon: Icons.person_search,
                    title: "Alunos Disponíveis",
                    count: alunosDisponiveis.length,
                  ),
                  const SizedBox(height: 12),

                  if (alunosDisponiveis.isEmpty)
                    _buildEmptyState(
                      icon: Icons.check_circle,
                      message: "Todos os alunos já estão nesta turma",
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alunosDisponiveis.length,
                    itemBuilder: (context, index) {
                      final studentDoc = alunosDisponiveis[index];
                      final student = studentDoc.data() as Map<String, dynamic>;
                      return _buildStudentCard(
                        student: student,
                        isEnrolled: false,
                        onPressed: () => _matricularAluno(studentDoc.id),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),

          // Relatórios
          _buildRelatoriosSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TurmaRelatorioPage(
                escolaId: widget.escolaId,
                turmaId: widget.turmaId,
                turmaNome: widget.turmaNome,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text(
          'Novo Relatório',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00A74F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required int count}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00A74F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF00A74F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00A74F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF00A74F),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard({required Map<String, dynamic> student, required bool isEnrolled, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00A74F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              student['nome'] != null && student['nome'].isNotEmpty
                  ? student['nome'][0].toUpperCase()
                  : "?",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A74F),
              ),
            ),
          ),
        ),
        title: Text(
          student['nome'] ?? 'Sem nome',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        trailing: SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnrolled
                  ? Colors.red.shade50
                  : const Color(0xFF00A74F),
              foregroundColor: isEnrolled
                  ? Colors.red
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              isEnrolled ? "Remover" : "Matricular",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatoriosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.description,
          title: "Relatórios Salvos",
          count: 0, // Será atualizado pelo StreamBuilder
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('escolas')
              .doc(widget.escolaId)
              .collection('turmas')
              .doc(widget.turmaId)
              .collection('relatorios')
              .orderBy('data', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.description_outlined,
                message: "Nenhum relatório salvo para esta turma",
              );
            }

            final relatorios = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: relatorios.length,
              itemBuilder: (context, index) {
                final relatorioDoc = relatorios[index];
                final relatorio = relatorioDoc.data() as Map<String, dynamic>;
                final data = (relatorio['data'] as Timestamp?)?.toDate();
                final formattedDate = data != null
                    ? DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(data)
                    : 'Data indisponível';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      "Relatório de $formattedDate",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      relatorio['conteudo'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A74F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFF00A74F),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisualizarRelatorioPage(
                            relatorio: relatorioDoc,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}