import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      await user.verifyBeforeUpdateEmail(_emailCtrl.text.trim());

      await _authService.updateUser(uid, {
        'nome': _nameCtrl.text.trim(),
        'cpf': _cpfCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Perfil atualizado! Verifique seu e-mail.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() ?? {};

          _nameCtrl.text = userData['nome'] ?? '';
          _cpfCtrl.text = userData['cpf'] ?? '';
          _emailCtrl.text = userData['email'] ?? '';

          final role = userData['role'] ?? 'responsavel';
          final escolaId = userData['escolaId'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(userData['nome']),
                  const SizedBox(height: 24),

                  _buildEditCard(userData, role, escolaId),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _updateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Salvar Alterações",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String? nome) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green,
          child: const Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          nome ?? "Usuário",
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildEditCard(
      Map<String, dynamic> userData, String role, String? escolaId) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextFormField(controller: _nameCtrl, label: "Nome"),
            _buildTextFormField(controller: _cpfCtrl, label: "CPF"),
            _buildTextFormField(controller: _emailCtrl, label: "E-mail"),

            const SizedBox(height: 16),
            if (role == "gestao") ...[
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("escolas")
                    .doc(escolaId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Escola: não vinculada",
                        style: TextStyle(color: Colors.black54));
                  }
                  final escola = snapshot.data!.data() as Map<String, dynamic>;
                  return Text("Escola: ${escola['nome'] ?? 'Sem nome'}",
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87));
                },
              ),
            ],

            if (role == "responsavel") ...[
              const Text("Responsável por:",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
              const SizedBox(height: 6),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection("students")
                    .where("responsibleCpf", isEqualTo: userData['cpf'])
                    .where("escolaId", isEqualTo: escolaId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text("Carregando alunos...");
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Text("Nenhum aluno vinculado");
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data!.docs.map((doc) {
                      final aluno = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(aluno['nome'] ?? "Sem nome",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87)),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      {required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}
