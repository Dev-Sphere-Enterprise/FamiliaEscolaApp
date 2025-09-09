import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TurmaRelatorioPage extends StatefulWidget {
  final String escolaId;
  final String turmaId;
  final String turmaNome;

  const TurmaRelatorioPage({
    super.key,
    required this.escolaId,
    required this.turmaId,
    required this.turmaNome,
  });

  @override
  State<TurmaRelatorioPage> createState() => _TurmaRelatorioPageState();
}

class _TurmaRelatorioPageState extends State<TurmaRelatorioPage> {
  final _formKey = GlobalKey<FormState>();
  final _relatorioCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _relatorioCtrl.dispose();
    super.dispose();
  }

  Future<void> _gerarRelatorio(int totalAlunos) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('escolas')
          .doc(widget.escolaId)
          .collection('turmas')
          .doc(widget.turmaId)
          .collection('relatorios')
          .add({
        'conteudo': _relatorioCtrl.text.trim(),
        'totalAlunos': totalAlunos,
        'data': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar relatório: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Relatório - ${widget.turmaNome}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('escolaId', isEqualTo: widget.escolaId)
            .where('turmaId', isEqualTo: widget.turmaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar alunos.'));
          }

          final alunosMatriculados = snapshot.data?.docs ?? [];
          final totalAlunos = alunosMatriculados.length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildHeader(totalAlunos),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _relatorioCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Informações do Relatório',
                      hintText:
                      'Digite aqui as observações, atividades e o desempenho geral da turma.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Este campo não pode estar vazio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : () => _gerarRelatorio(totalAlunos),
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: const Text('Salvar Relatório'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int totalAlunos) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total de Alunos na Turma:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '$totalAlunos',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}