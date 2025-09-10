import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdicionarAvisoPage extends StatefulWidget {
  final String? avisoId;
  final Map<String, dynamic>? aviso;

  const AdicionarAvisoPage({super.key, this.avisoId, this.aviso});

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

    // se estiver em edição, pré-seleciona os dados
    if (widget.aviso != null) {
      final aviso = widget.aviso!;
      _destino = aviso['destino'] ?? "escola";
      _turmasSelecionadas = List<String>.from(aviso['turmaIds'] ?? []);
      _alunosSelecionados = List<String>.from(aviso['alunoIds'] ?? []);
    }
  }

  Future<void> _salvarAviso() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ Validações
    if (_tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O título do aviso é obrigatório"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mensagemCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A mensagem do aviso é obrigatória"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

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

      if (widget.avisoId == null) {
        // ➕ Novo aviso
        await FirebaseFirestore.instance.collection('avisos').add({
          'titulo': _tituloCtrl.text.trim(),
          'mensagem': _mensagemCtrl.text.trim(),
          'data': FieldValue.serverTimestamp(),
          'lidoPor': [],
          'escolaId': escolaId,
          'criadoPor': uid,
          'destino': _destino,
          'turmaIds': _destino == "turma" ? _turmasSelecionadas : [],
          'alunoIds': _destino == "aluno" ? _alunosSelecionados : [],
        });
      } else {
        // ✏️ Editar aviso existente
        await FirebaseFirestore.instance
            .collection('avisos')
            .doc(widget.avisoId)
            .update({
          'titulo': _tituloCtrl.text.trim(),
          'mensagem': _mensagemCtrl.text.trim(),
          'destino': _destino,
          'turmaIds': _destino == "turma" ? _turmasSelecionadas : [],
          'alunoIds': _destino == "aluno" ? _alunosSelecionados : [],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.avisoId == null
                ? 'Aviso criado com sucesso!'
                : 'Aviso atualizado com sucesso!'),
            backgroundColor: const Color(0xFF00A74F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar aviso: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  void initState() {
    super.initState();

    // Preencher campos se for edição
    if (widget.aviso != null) {
      _tituloCtrl.text = widget.aviso!['titulo'] ?? '';
      _mensagemCtrl.text = widget.aviso!['mensagem'] ?? '';
    }

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
    final isEdicao = widget.avisoId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdicao ? "Editar Aviso" : "Novo Aviso",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Campos do formulário
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text(
                      'Título do Aviso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tituloCtrl,
                      decoration: InputDecoration(
                        hintText: "Digite o título do aviso",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00A74F), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mensagem
                    const Text(
                      'Mensagem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mensagemCtrl,
                      decoration: InputDecoration(
                        hintText: "Digite a mensagem do aviso",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00A74F), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      maxLines: 5,
                    ),

                    const SizedBox(height: 24),

                    // Destino do aviso
                    const Text(
                      'Destinatário',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _destino,
                          isExpanded: true,
                          // menuMaxHeight: 300,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00A74F)),
                          items: const [
                            DropdownMenuItem(
                              value: "escola",
                              child: ListTile(
                                leading: Icon(Icons.school, color: Color(0xFF00A74F)),
                                title: Text("Toda a Escola"),
                                subtitle: Text("Todos os alunos e responsáveis"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "turma",
                              child: ListTile(
                                leading: Icon(Icons.group, color: Color(0xFF00A74F)),
                                title: Text("Turma específica"),
                                subtitle: Text("Selecione uma ou mais turmas"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "aluno",
                              child: ListTile(
                                leading: Icon(Icons.person, color: Color(0xFF00A74F)),
                                title: Text("Aluno específico"),
                                subtitle: Text("Selecione um ou mais alunos"),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _destino = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Listas de seleção
                    if (_destino == "turma") ...[
                      const Text(
                        'Selecionar Turmas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _turmas.isEmpty
                          ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhuma turma encontrada',
                            style: TextStyle(color: Color(0xFF718096)),
                          ),
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: _turmas.map((doc) {
                            final turmaId = doc.id;
                            final nome = doc["nome"] ?? "Turma sem nome";
                            final selected = _turmasSelecionadas.contains(turmaId);
                            return CheckboxListTile(
                              title: Text(
                                nome,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: selected,
                              activeColor: const Color(0xFF00A74F),
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
                    ],

                    if (_destino == "aluno") ...[
                      const Text(
                        'Selecionar Alunos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _alunos.isEmpty
                          ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhum aluno encontrado',
                            style: TextStyle(color: Color(0xFF718096)),
                          ),
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: _alunos.map((doc) {
                            final alunoId = doc.id;
                            final nome = doc["nome"] ?? "Aluno sem nome";
                            final selected = _alunosSelecionados.contains(alunoId);
                            return CheckboxListTile(
                              title: Text(
                                nome,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: selected,
                              activeColor: const Color(0xFF00A74F),
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
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarAviso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A74F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEdicao ? "Atualizar Aviso" : "Publicar Aviso",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}