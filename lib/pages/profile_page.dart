import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'student_service.dart'; // Importe o novo serviço
import 'profile_edit_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final studentService = StudentService(); // Crie uma instância do serviço
    final uid = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: const Text("Informações do Responsável"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botão para navegar para a tela de edição
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navega para a tela de edição
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileEditPage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: authService.getUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                // Nova seção para exibir os alunos
                if (uid != null)
                  StreamBuilder<List<DocumentSnapshot>>(
                    stream: studentService.getStudentsForResponsible(uid),
                    builder: (context, studentSnapshot) {
                      if (!studentSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final students = studentSnapshot.data!;
                      if (students.isEmpty) {
                        return const Text('Nenhum aluno vinculado.');
                      }
                      return _buildStudentsList(students);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      // Copiando a BottomNavigationBar da HomePage para consistência
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Novo widget para construir a lista de alunos
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
      color: const Color(0xFFD9D9D9), // Cinza claro semelhante ao da imagem
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0, // sem sombra para ficar igual à imagem
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

  // BottomNavigationBar para manter a consistência
  BottomNavigationBar _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4, // Perfil
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 2) Navigator.pop(context); // Volta pra Home
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