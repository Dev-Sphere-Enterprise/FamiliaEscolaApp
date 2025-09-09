import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  DateTime? _birthDate; // ✅ guarda a data real
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
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data de nascimento")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Usuário não autenticado");

      final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final escolaId = userDoc.data()?["escolaId"];
      if (escolaId == null) throw Exception("Gestor não vinculado a nenhuma escola");

      await FirebaseFirestore.instance.collection("students").add({
        "nome": _studentNameCtrl.text.trim(),
        // ✅ salva como Timestamp no Firestore
        "dataNascimento": Timestamp.fromDate(_birthDate!),
        "responsibleName": _responsibleNameCtrl.text.trim(),
        "responsibleCpf": _responsibleCpfCtrl.text.trim(),
        "escolaId": escolaId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Aluno adicionado com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro ao adicionar aluno: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale("pt", "BR"),
    );
    if (picked != null) {
      _birthDate = picked; // ✅ guarda para salvar no Firestore
      _studentBirthDateCtrl.text =
      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  String? _validateCpf(String? value) {
    if (value == null || value.isEmpty) return "Informe o CPF do responsável";
    if (value.length != 11) return "CPF deve ter 11 dígitos";
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Aluno"),
        backgroundColor: Colors.blue,
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
                decoration: const InputDecoration(
                  labelText: "Nome do Aluno",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Informe o nome do aluno" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _studentBirthDateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: "Data de Nascimento",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v == null || v.isEmpty ? "Informe a data de nascimento" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _responsibleNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nome do Responsável",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Informe o nome do responsável" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _responsibleCpfCtrl,
                decoration: const InputDecoration(
                  labelText: "CPF do Responsável",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: _validateCpf,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _loading ? null : _addStudent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Adicionar Aluno", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}