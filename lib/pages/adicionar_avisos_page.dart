import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarAvisoPage extends StatefulWidget {
  const AdicionarAvisoPage({super.key});

  @override
  State<AdicionarAvisoPage> createState() => _AdicionarAvisoPageState();
}

class _AdicionarAvisoPageState extends State<AdicionarAvisoPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarAviso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final usuariosSnapshot = await FirebaseFirestore.instance.collection('users').get();

      final batch = FirebaseFirestore.instance.batch();
      for (var userDoc in usuariosSnapshot.docs) {
        final avisoRef = FirebaseFirestore.instance
            .collection('avisosUsuarios')
            .doc(userDoc.id)
            .collection('itens')
            .doc();

        batch.set(avisoRef, {
          'titulo': _tituloCtrl.text.trim(),
          'mensagem': _mensagemCtrl.text.trim(),
          'data': DateTime.now(),
          'lido': false,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aviso adicionado com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar aviso: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Aviso")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v!.isEmpty ? "Informe um título" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mensagemCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Mensagem"),
                validator: (v) => v!.isEmpty ? "Informe uma mensagem" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _salvarAviso,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Salvar"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
