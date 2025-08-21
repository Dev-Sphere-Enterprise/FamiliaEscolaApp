import 'package:flutter/material.dart';
import '../services/school_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSchoolPage extends StatefulWidget {
  final DocumentSnapshot schoolDocument;

  const EditSchoolPage({super.key, required this.schoolDocument});

  @override
  State<EditSchoolPage> createState() => _EditSchoolPageState();
}

class _EditSchoolPageState extends State<EditSchoolPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _schoolTypeCtrl;
  late TextEditingController _otherDataCtrl;

  bool _loading = false;
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    final schoolData = widget.schoolDocument.data() as Map<String, dynamic>;
    _schoolNameCtrl = TextEditingController(text: schoolData['nome'] ?? '');
    _schoolTypeCtrl = TextEditingController(text: schoolData['tipo'] ?? '');
    _otherDataCtrl = TextEditingController(text: schoolData['outros_dados'] ?? '');
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _schoolTypeCtrl.dispose();
    _otherDataCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _schoolService.updateSchool(
        schoolId: widget.schoolDocument.id,
        schoolName: _schoolNameCtrl.text.trim(),
        schoolType: _schoolTypeCtrl.text.trim(),
        otherData: _otherDataCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escola atualizada com sucesso!')),
        );
        Navigator.pop(context); // Volta para tela anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar escola: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Escola')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _schoolNameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Escola'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schoolTypeCtrl,
                decoration: const InputDecoration(labelText: 'Tipo (Ex: Pública, Particular)'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otherDataCtrl,
                decoration: const InputDecoration(labelText: 'Outras Informações (Endereço, etc.)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _updateSchool,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
