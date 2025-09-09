import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisualizarRelatorioPage extends StatelessWidget {
  final DocumentSnapshot relatorio;

  const VisualizarRelatorioPage({super.key, required this.relatorio});

  @override
  Widget build(BuildContext context) {
    final data = relatorio.data() as Map<String, dynamic>;
    final conteudo = data['conteudo'] ?? 'Nenhum conteúdo informado.';
    final totalAlunos = data['totalAlunos'] ?? 0;
    final timestamp = (data['data'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(timestamp)
        : 'Data indisponível';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Relatório'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Relatório de $formattedDate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total de alunos na turma: $totalAlunos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const Divider(height: 32),
          Text(
            'Observações:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              conteudo,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
