import 'package:FamiliaEscolaApp/pages/dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/school_service.dart';
import 'edit_school_page.dart';

class SchoolDetailsPage extends StatelessWidget {
  final String schoolId;
  const SchoolDetailsPage({super.key, required this.schoolId});

  Future<bool> _isGestor() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return false;

    final data = doc.data();
    return data?['role'] == 'gestao';
  }

  @override
  Widget build(BuildContext context) {
    final schoolService = SchoolService();

    return FutureBuilder<bool>(
      future: _isGestor(),
      builder: (context, snapshot) {
        final isGestor = snapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Dados da Escola',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF00A74F),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: isGestor
                ? [
              // Botão de editar
              IconButton(
                icon: const Icon(Icons.edit, size: 22),
                onPressed: () async {
                  try {
                    final schoolDoc =
                    await schoolService.getSchoolData(schoolId);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditSchoolPage(schoolDocument: schoolDoc),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Erro ao carregar dados da escola: $e")),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.dashboard, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(escolaId: schoolId),
                    ),
                  );
                },
              ),
              // Botão de deletar
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                onPressed: () => _confirmDelete(context, schoolService),
              ),
            ]
                : null,
          ),
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: schoolService.getSchoolStream(schoolId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Escola não encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final schoolData = snapshot.data!.data() ?? {};

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com ícone
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A74F).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 30,
                              color: Color(0xFF00A74F),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolData['nome'] ?? 'Nome não informado',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  schoolData['tipo'] ?? 'Tipo não informado',
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

                    const SizedBox(height: 8),

                    // Informações da escola
                    const Text(
                      'Informações da Escola',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildInfoCard(
                            icon: Icons.business,
                            title: "Nome da Escola",
                            value: schoolData['nome'] ?? 'Não informado',
                          ),
                          _buildInfoCard(
                            icon: Icons.category,
                            title: "Tipo de Escola",
                            value: schoolData['tipo'] ?? 'Não informado',
                          ),
                          _buildInfoCard(
                            icon: Icons.info_outline,
                            title: "Outras Informações",
                            value: schoolData['info']?.isNotEmpty == true
                                ? schoolData['info']
                                : 'Nenhuma informação adicional',
                            isMultiline: true,
                          ),
                          if (schoolData['endereco']?.isNotEmpty == true)
                            _buildInfoCard(
                              icon: Icons.location_on,
                              title: "Endereço",
                              value: schoolData['endereco'],
                            ),
                          if (schoolData['telefone']?.isNotEmpty == true)
                            _buildInfoCard(
                              icon: Icons.phone,
                              title: "Telefone",
                              value: schoolData['telefone'],
                            ),
                          if (schoolData['email']?.isNotEmpty == true)
                            _buildInfoCard(
                              icon: Icons.email,
                              title: "Email",
                              value: schoolData['email'],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00A74F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF00A74F)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
            maxLines: isMultiline ? null : 2,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SchoolService schoolService) {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Excluir Escola"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Digite sua senha para confirmar a exclusão da escola:",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final cred = EmailAuthProvider.credential(
                  email: user.email!,
                  password: passwordCtrl.text,
                );

                try {
                  await user.reauthenticateWithCredential(cred);
                  await schoolService.deleteSchool(schoolId);

                  if (context.mounted) {
                    Navigator.of(ctx).pop(); // fecha o dialog
                    Navigator.of(context).pop(); // volta para a tela anterior
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Escola excluída com sucesso'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }
}
