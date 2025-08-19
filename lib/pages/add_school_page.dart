import 'package:flutter/material.dart';
import '../services/school_service.dart';

class AddSchoolPage extends StatefulWidget {
  const AddSchoolPage({super.key});

  @override
  State<AddSchoolPage> createState() => _AddSchoolPageState();
}

class _AddSchoolPageState extends State<AddSchoolPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameCtrl = TextEditingController();
  final _schoolTypeCtrl = TextEditingController();
  final _otherDataCtrl = TextEditingController();

  bool _loading = false;
  final SchoolService _schoolService = SchoolService();

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _schoolTypeCtrl.dispose();
    _otherDataCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _schoolService.addSchool(
        schoolName: _schoolNameCtrl.text.trim(),
        schoolType: _schoolTypeCtrl.text.trim(),
        otherData: _otherDataCtrl.text.trim(),
      );

      // A navegação será tratada pelo AuthGate, que irá reavaliar o estado
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar escola: $e')),
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
        title: const Text('Cadastre sua Escola'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bem-vindo, Gestor!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para continuar, por favor, cadastre as informações da sua escola.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _schoolNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da Escola'),
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _schoolTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo (Ex: Particular, Pública)'),
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherDataCtrl,
                  decoration: const InputDecoration(labelText: 'Outras Informações (Endereço, etc.)'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _addSchool,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar e Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}