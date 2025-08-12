import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  // Controllers para os campos do formulário
  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = _authService.currentUser!.uid;
      await _authService.updateUser(uid, {
        'nome': _nameCtrl.text.trim(),
        'cpf': _cpfCtrl.text.trim(),
        'dataNascimento': _birthDateCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!")),
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
      backgroundColor: const Color(0xFF333333),
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() ?? {};

          // Preenche os controllers com os dados existentes
          _nameCtrl.text = userData['nome'] ?? '';
          _cpfCtrl.text = userData['cpf'] ?? '';
          _birthDateCtrl.text = userData['dataNascimento'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E86C1), Color(0xFF28B463)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEditCard(userData),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _updateUser,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28a745),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Salvar", style: TextStyle(fontSize: 18)),
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

  Widget _buildEditCard(Map<String, dynamic> userData) {
    return Card(
      color: const Color(0xFFE0E0E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextFormField(controller: _nameCtrl, label: "Nome:"),
            _buildTextFormField(controller: _cpfCtrl, label: "CPF:"),
            _buildTextFormField(controller: _birthDateCtrl, label: "Data de Nascimento:"),
            // Exemplo de campo não editável
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Responsável por:", style: TextStyle(color: Colors.black54, fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Júlio César de Menezes Duarte", style: TextStyle(color: Colors.black87, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal),
          border: InputBorder.none, // Remove a borda
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}