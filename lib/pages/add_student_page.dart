import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameCtrl = TextEditingController();
  final _studentBirthDateCtrl = TextEditingController();
  final _responsibleNameCtrl = TextEditingController();
  final _responsibleCpfCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _studentBirthDateCtrl.dispose();
    _responsibleNameCtrl.dispose();
    _responsibleCpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Usuário não autenticado");

      // pega a escola do gestor logado
      final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final escolaId = userDoc.data()?["escolaId"];
      if (escolaId == null) throw Exception("Gestor não vinculado a nenhuma escola");

      // cria aluno na coleção RAIZ "students"
      final alunoRef = await FirebaseFirestore.instance.collection("students").add({
        "nome": _studentNameCtrl.text.trim(),
        "dataNascimento": _studentBirthDateCtrl.text.trim(),
        "responsibleName": _responsibleNameCtrl.text.trim(),
        "responsibleCpf": _responsibleCpfCtrl.text.trim(),
        "escolaId": escolaId, // 🔗 vínculo com a escola
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aluno adicionado com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar aluno: $e")),
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
        title: const Text("Adicionar Aluno"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _studentNameCtrl,
                decoration: const InputDecoration(labelText: "Nome do Aluno"),
                validator: (v) => v == null || v.isEmpty ? "Informe o nome do aluno" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentBirthDateCtrl,
                decoration: const InputDecoration(labelText: "Data de Nascimento"),
                validator: (v) => v == null || v.isEmpty ? "Informe a data de nascimento" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibleNameCtrl,
                decoration: const InputDecoration(labelText: "Nome do Responsável"),
                validator: (v) => v == null || v.isEmpty ? "Informe o nome do responsável" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibleCpfCtrl,
                decoration: const InputDecoration(labelText: "CPF do Responsável"),
                validator: (v) => v == null || v.isEmpty ? "Informe o CPF do responsável" : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _addStudent,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Adicionar Aluno"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
