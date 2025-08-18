import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/school_service.dart';
import 'edit_school_page.dart';

class SchoolDetailsPage extends StatelessWidget {
  final String schoolId;
  const SchoolDetailsPage({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final SchoolService schoolService = SchoolService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da Escola'),
        actions: [
          // Botão de deletar
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, schoolService),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: schoolService.getSchoolStream(schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Escola não encontrada.'));
          }
          final schoolData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildInfoCard("Nome", schoolData['nome'] ?? '...'),
                _buildInfoCard("Tipo", schoolData['tipo'] ?? '...'),
                _buildInfoCard("Outras Informações", schoolData['outros_dados'] ?? '...'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final schoolDoc = await schoolService.getSchoolData(schoolId);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditSchoolPage(schoolDocument: schoolDoc)),
            );
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SchoolService schoolService) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza de que deseja excluir esta escola? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await schoolService.deleteSchool(schoolId);
                  if (context.mounted) {
                    Navigator.of(ctx).pop(); // Fecha o dialog
                    Navigator.of(context).pop(); // Volta para a HomePage (que irá redirecionar)
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir escola: $e')),
                    );
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}