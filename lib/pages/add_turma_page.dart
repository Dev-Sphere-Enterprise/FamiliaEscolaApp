import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTurmaPage extends StatefulWidget {
  const AddTurmaPage({super.key});

  @override
  State<AddTurmaPage> createState() => _AddTurmaPageState();
}

class _AddTurmaPageState extends State<AddTurmaPage> {
  final _formKey = GlobalKey<FormState>();
  final _turmaNameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _turmaNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTurma() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Usuário não autenticado");

      // pega a escola do gestor logado
      final userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final escolaId = userDoc.data()?["escolaId"];
      if (escolaId == null) {
        throw Exception("Gestor não vinculado a nenhuma escola");
      }

      await FirebaseFirestore.instance
          .collection("escolas")
          .doc(escolaId)
          .collection("turmas")
          .add({
        "nome": _turmaNameCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Turma adicionada com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar turma: $e")),
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
        title: const Text("Adicionar Turma"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _turmaNameCtrl,
                decoration: const InputDecoration(labelText: "Nome da Turma"),
                validator: (v) =>
                v == null || v.isEmpty ? "Informe o nome da turma" : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _addTurma,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Adicionar Turma"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}