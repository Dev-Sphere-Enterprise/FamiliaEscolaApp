import 'package:FamiliaEscolaApp/pages/student_service.dart';
import 'package:flutter/material.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameCtrl = TextEditingController();
  final _responsibleNameCtrl = TextEditingController();
  final _responsibleCpfCtrl = TextEditingController();
  final _studentBirthDateCtrl = TextEditingController();

  bool _loading = false;
  final StudentService _studentService = StudentService();

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _responsibleNameCtrl.dispose();
    _responsibleCpfCtrl.dispose();
    _studentBirthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _studentService.addStudent(
        studentName: _studentNameCtrl.text.trim(),
        studentBirthDate: _studentBirthDateCtrl.text.trim(),
        responsibleName: _responsibleNameCtrl.text.trim(),
        responsibleCpf: _responsibleCpfCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno adicionado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar aluno: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Aluno'),
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
                decoration: const InputDecoration(labelText: 'Nome do Aluno'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do aluno';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentBirthDateCtrl,
                decoration: const InputDecoration(labelText: 'Data de Nascimento do Aluno'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de nascimento do aluno';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibleNameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Responsável'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do responsável';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibleCpfCtrl,
                decoration: const InputDecoration(labelText: 'CPF do Responsável'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o CPF do responsável';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _addStudent,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Adicionar Aluno'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}