import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'add_student_page.dart'; 

class HomePage extends StatelessWidget {
  final String nomeUsuario;
  final String tipoPerfil;

  const HomePage({
    super.key,
    required this.nomeUsuario,
    required this.tipoPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final isGestor = tipoPerfil.toLowerCase() == 'gestao';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: Text("Tela Inicial"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Olá, $nomeUsuario!",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Quadro de Avisos
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Quadro de Avisos",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botões de Atalho
            Center(
              child: Wrap(
                spacing: 50,
                runSpacing: 50,
                children: [
                  _menuButton("Alunos", Icons.people, () {}),
                  _menuButton("Escola", Icons.school, () {}),
                  _menuButton("Turmas", Icons.class_, () {}),
                  _menuButton("Chat", Icons.chat, () {}),
                  // Botão para adicionar aluno, visível apenas para o gestor
                  if (isGestor)
                    _menuButton("Adicionar Aluno", Icons.person_add, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddStudentPage()),
                      );
                    }),
                ],
              ),
            )
          ],
        ),
      ),

      // Menu Inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 4){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
          if (index == 0) {
            FirebaseAuth.instance.signOut();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: "Sair"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Avisos"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Mensagens"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _menuButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}