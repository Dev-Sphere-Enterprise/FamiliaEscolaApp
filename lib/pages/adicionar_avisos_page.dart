import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdicionarAvisoPage extends StatefulWidget {
  const AdicionarAvisoPage({super.key});

  @override
  State<AdicionarAvisoPage> createState() => _AdicionarAvisoPageState();
}

class _AdicionarAvisoPageState extends State<AdicionarAvisoPage> {
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _salvarAviso() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      // 🔎 Buscar o user logado para pegar a escolaId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário não encontrado")),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final escolaId = userData['escolaId'];

      if (escolaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário não vinculado a nenhuma escola")),
        );
        return;
      }

      // ➕ Criar aviso já com a escolaId
      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': _tituloCtrl.text,
        'mensagem': _mensagemCtrl.text,
        'data': DateTime.now(),
        'lidoPor': [],
        'escolaId': escolaId, // 🔗 vincula à escola
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar aviso: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Aviso"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mensagemCtrl,
              decoration: const InputDecoration(labelText: "Mensagem"),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _salvarAviso,
              icon: const Icon(Icons.save),
              label: const Text("Salvar Aviso"),
            ),
          ],
        ),
      ),
    );
  }
}
