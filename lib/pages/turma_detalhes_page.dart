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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao matricular aluno: $e")),
      );
    }
  }

  Future<void> _desmatricularAluno(String studentId) async {
    try {
      final studentRef =
      FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({'turmaId': FieldValue.delete()});
    } catch (e) {
      if (!mounted) return;
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
      body: ListView(
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
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Erro ao carregar alunos."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("Nenhum aluno encontrado nesta escola."));
              }

              final allStudents = snapshot.data!.docs;
              final alunosMatriculados = allStudents
                  .where((doc) =>
              (doc.data() as Map<String, dynamic>)['turmaId'] ==
                  widget.turmaId)
                  .toList();
              final alunosDisponiveis = allStudents
                  .where((doc) =>
              (doc.data() as Map<String, dynamic>)['turmaId'] !=
                  widget.turmaId)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      "Alunos Matriculados (${alunosMatriculados.length})"),
                  if (alunosMatriculados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text("Nenhum aluno matriculado nesta turma."),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alunosMatriculados.length,
                    itemBuilder: (context, index) {
                      final studentDoc = alunosMatriculados[index];
                      final student =
                      studentDoc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(student['nome'] ?? 'Sem nome'),
                          trailing: TextButton(
                            child: const Text("Desmatricular",
                                style: TextStyle(color: Colors.red)),
                            onPressed: () =>
                                _desmatricularAluno(studentDoc.id),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildSectionTitle(
                      "Alunos Disponíveis (${alunosDisponiveis.length})"),
                  if (alunosDisponiveis.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child:
                      Text("Todos os alunos da escola já estão nesta turma."),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alunosDisponiveis.length,
                    itemBuilder: (context, index) {
                      final studentDoc = alunosDisponiveis[index];
                      final student =
                      studentDoc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(student['nome'] ?? 'Sem nome'),
                          trailing: ElevatedButton(
                            child: const Text("Matricular"),
                            onPressed: () => _matricularAluno(studentDoc.id),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(height: 32, thickness: 2, indent: 16, endIndent: 16),
          _buildRelatoriosSection(),
          const SizedBox(height: 80), // Espaço para o botão flutuante
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
        label: const Text('Novo Relatório'),
        icon: const Icon(Icons.add_chart),
      ),
    );
  }

  Widget _buildRelatoriosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Relatórios Salvos"),
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
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Nenhum relatório salvo para esta turma."),
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

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined, color: Colors.blueAccent),
                    title: Text("Relatório de $formattedDate"),
                    subtitle: Text(
                      relatorio['conteudo'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
