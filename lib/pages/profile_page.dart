import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../widgets/main_scaffold.dart';

import 'profile_edit_page.dart';
import 'school_details_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final studentService = StudentService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    // 🔄 Sempre puxa os dados do usuário logado no Firestore
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: Text("Dados do usuário não encontrados")),
          );
        }

        final userData = snapshot.data!.data()!;
        final tipoPerfil = userData['role'] ?? 'responsavel';
        final schoolId = userData['id_escola'];

        return MainScaffold(
          currentIndex: 4, // Perfil ativo
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9C84F), Color(0xFFF2A900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(userData),
                const SizedBox(height: 24),

                // Botão Editar Perfil
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar Perfil"),
                  ),
                ),

                const SizedBox(height: 24),

                // Card da gestão → Gerenciar Escola
                if (tipoPerfil == 'gestao' && schoolId != null)
                  _buildManageSchoolCard(context, schoolId),

                // Lista de alunos → apenas para responsáveis
                if (tipoPerfil == 'responsavel')
                  Builder(
                    builder: (context) {
                      final cpf = userData['cpf'];
                      if (cpf == null || cpf.toString().isEmpty) {
                        return const Center(
                          child: Text("CPF não encontrado para este usuário."),
                        );
                      }
                      return StreamBuilder<List<DocumentSnapshot>>(
                        stream: studentService.getStudentsForResponsibleByCpf(cpf),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
                            return const Center(child: Text('Nenhum aluno vinculado.'));
                          }
                          final students = studentSnapshot.data!;
                          return _buildStudentsList(students);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManageSchoolCard(BuildContext context, String schoolId) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.school, color: Colors.blueAccent),
        title: const Text('Gerenciar Escola'),
        subtitle: const Text('Editar ou excluir os dados da sua escola'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailsPage(schoolId: schoolId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsList(List<DocumentSnapshot> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alunos Vinculados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final studentData = students[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(studentData['name'] ?? 'Nome não encontrado'),
                subtitle: Text('Nascimento: ${studentData['birthDate'] ?? '...'}'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader({required Gradient gradient}) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.person, size: 120, color: Colors.white),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> userData) {
    return Card(
      color: const Color(0xFFD9D9D9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Nome:", userData['name'] ?? '...'),
            const SizedBox(height: 8),
            _buildInfoRow("CPF:", userData['cpf'] ?? '...'),
            const SizedBox(height: 8),
            _buildInfoRow("Data de Nascimento:", userData['dataNascimento'] ?? '...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
