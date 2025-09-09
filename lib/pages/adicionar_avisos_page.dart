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

  String _destino = "escola"; // escola | turma | aluno
  List<String> _turmasSelecionadas = [];
  List<String> _alunosSelecionados = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _turmas = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _alunos = [];

  Future<void> _carregarDados(String escolaId) async {
    // Buscar turmas
    final turmasSnap = await FirebaseFirestore.instance
        .collection("escolas")
        .doc(escolaId)
        .collection("turmas")
        .get();
    final alunosSnap = await FirebaseFirestore.instance
        .collection("students")
        .where("escolaId", isEqualTo: escolaId)
        .get();

    setState(() {
      _turmas = turmasSnap.docs;
      _alunos = alunosSnap.docs;
    });
  }

  Future<void> _salvarAviso() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      // 🔎 Buscar user logado para pegar escolaId
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

      // ➕ Criar aviso já com destino
      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': _tituloCtrl.text,
        'mensagem': _mensagemCtrl.text,
        'data': FieldValue.serverTimestamp(),
        'lidoPor': [],
        'escolaId': escolaId,
        'criadoPor': uid,
        'destino': _destino,
        'turmaIds': _destino == "turma" ? _turmasSelecionadas : [],
        'alunoIds': _destino == "aluno" ? _alunosSelecionados : [],
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar aviso: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Buscar escolaId do gestor logado para carregar turmas/alunos
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection("users").doc(uid).get().then((doc) {
        final data = doc.data();
        if (data != null && data["escolaId"] != null) {
          _carregarDados(data["escolaId"]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Aviso")),
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

            DropdownButton<String>(
              value: _destino,
              items: const [
                DropdownMenuItem(value: "escola", child: Text("Toda a Escola")),
                DropdownMenuItem(value: "turma", child: Text("Turma específica")),
                DropdownMenuItem(value: "aluno", child: Text("Aluno específico")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _destino = val);
              },
            ),

            if (_destino == "turma") Expanded(
              child: ListView(
                children: _turmas.map((doc) {
                  final turmaId = doc.id;
                  final nome = doc["nome"] ?? "Turma sem nome";
                  final selected = _turmasSelecionadas.contains(turmaId);
                  return CheckboxListTile(
                    title: Text(nome),
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _turmasSelecionadas.add(turmaId);
                        } else {
                          _turmasSelecionadas.remove(turmaId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            if (_destino == "aluno") Expanded(
              child: ListView(
                children: _alunos.map((doc) {
                  final alunoId = doc.id;
                  final nome = doc["nome"] ?? "Aluno sem nome";
                  final selected = _alunosSelecionados.contains(alunoId);
                  return CheckboxListTile(
                    title: Text(nome),
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _alunosSelecionados.add(alunoId);
                        } else {
                          _alunosSelecionados.remove(alunoId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
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
