import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/school_service.dart'; // Corrigido e adicionado
import '../services/student_service.dart'; // Corrigido
import 'profile_edit_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final studentService = StudentService();
    final schoolService = SchoolService(); // Instância do serviço da escola
    final uid = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: const Text("Informações do Perfil"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: authService.getUserStream(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = userSnapshot.data!.data() ?? {};
          final tipoPerfil = userData['role'] ?? 'responsavel';

          return SingleChildScrollView(
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

                // --- LÓGICA PRINCIPAL ---
                // Se for gestor, busca e exibe o nome da escola
                if (tipoPerfil == 'gestao' && userData['id_escola'] != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: schoolService.getSchoolData(userData['id_escola']),
                    builder: (context, schoolSnapshot) {
                      if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!schoolSnapshot.hasData || !schoolSnapshot.data!.exists) {
                        return _buildInfoCard(userData, schoolName: 'Escola não encontrada');
                      }
                      final schoolData = schoolSnapshot.data!.data() as Map<String, dynamic>;
                      final schoolName = schoolData['nome'] ?? 'Nome da escola não informado';

                      return _buildInfoCard(userData, schoolName: schoolName);
                    },
                  )
                else
                // Se for responsável, mostra o card normal
                  _buildInfoCard(userData),

                const SizedBox(height: 24),

                // Se for responsável, mostra a lista de alunos
                if (uid != null && tipoPerfil == 'responsavel')
                  StreamBuilder<List<DocumentSnapshot>>(
                    stream: studentService.getStudentsForResponsible(uid),
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
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
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

  // Assinatura do método modificada para aceitar um parâmetro nomeado opcional
  Widget _buildInfoCard(Map<String, dynamic> userData, {String? schoolName}) {
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

            // Condição para exibir a linha da escola apenas se 'schoolName' for fornecido
            if (schoolName != null && schoolName.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow("Escola:", schoolName),
            ]
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

  BottomNavigationBar _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 2) Navigator.pop(context);
        if (index == 0) FirebaseAuth.instance.signOut();
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: "Sair"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Avisos"),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: "Mensagens"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}