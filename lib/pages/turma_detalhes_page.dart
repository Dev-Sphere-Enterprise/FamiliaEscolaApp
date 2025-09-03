import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  // Matricula o aluno na turma atual
  Future<void> _matricularAluno(String studentId) async {
    try {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({'turmaId': widget.turmaId});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao matricular aluno: $e")),
      );
    }
  }

  // Remove o aluno da turma
  Future<void> _desmatricularAluno(String studentId) async {
    try {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({'turmaId': FieldValue.delete()});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao desmatricular aluno: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Turma: ${widget.turmaNome}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('escolaId', isEqualTo: widget.escolaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum aluno encontrado nesta escola."));
          }

          final allStudents = snapshot.data!.docs;

          // Separa os alunos em duas listas
          final alunosMatriculados = allStudents.where((doc) => (doc.data() as Map<String, dynamic>)['turmaId'] == widget.turmaId).toList();
          final alunosDisponiveis = allStudents.where((doc) => (doc.data() as Map<String, dynamic>)['turmaId'] != widget.turmaId).toList();

          return ListView(
            children: [
              // Seção de Alunos Matriculados
              _buildSectionTitle("Alunos Matriculados (${alunosMatriculados.length})"),
              if (alunosMatriculados.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text("Nenhum aluno matriculado nesta turma."),
                ),
              ...alunosMatriculados.map((studentDoc) {
                final student = studentDoc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(student['nome'] ?? 'Sem nome'),
                    trailing: TextButton(
                      child: const Text("Desmatricular", style: TextStyle(color: Colors.red)),
                      onPressed: () => _desmatricularAluno(studentDoc.id),
                    ),
                  ),
                );
              }),

              const Divider(height: 32, thickness: 1),

              // Seção de Alunos Disponíveis
              _buildSectionTitle("Alunos Disponíveis (${alunosDisponiveis.length})"),
              if (alunosDisponiveis.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text("Todos os alunos da escola já estão nesta turma."),
                ),
              ...alunosDisponiveis.map((studentDoc) {
                final student = studentDoc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(student['nome'] ?? 'Sem nome'),
                    trailing: ElevatedButton(
                      child: const Text("Matricular"),
                      onPressed: () => _matricularAluno(studentDoc.id),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}