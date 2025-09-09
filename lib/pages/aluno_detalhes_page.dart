import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'adicionar_registro_aluno_page.dart';

class AlunoDetalhesPage extends StatefulWidget {
  final String alunoId;
  const AlunoDetalhesPage({super.key, required this.alunoId});

  @override
  State<AlunoDetalhesPage> createState() => _AlunoDetalhesPageState();
}

class _AlunoDetalhesPageState extends State<AlunoDetalhesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _ehGestor = false;
  bool _loadingPermission = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verificarPermissao();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verificarPermissao() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingPermission = false);
      return;
    }
    final userDoc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (mounted) {
      setState(() {
        _ehGestor = userDoc.data()?['role'] == "gestao";
        _loadingPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Aluno"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: "Informações"),
            Tab(icon: Icon(Icons.description), text: "Relatórios"),
            Tab(icon: Icon(Icons.warning), text: "Ocorrências"),
          ],
        ),
      ),
      body: _loadingPermission
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(widget.alunoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Aluno não encontrado."));
          }

          final aluno = snapshot.data!.data() as Map<String, dynamic>;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(aluno),
              _buildRegistrosList("Relatório"),
              _buildRegistrosList("Ocorrência"),
            ],
          );
        },
      ),
      floatingActionButton: _ehGestor
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdicionarRegistroAlunoPage(
                alunoId: widget.alunoId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add_comment),
        tooltip: 'Adicionar Registro',
      )
          : null,
    );
  }

  Widget _buildInfoTab(Map<String, dynamic> aluno) {
    final escolaId = aluno['escolaId'];
    final turmaId = aluno['turmaId'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade200,
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          aluno['nome'] ?? '---',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _infoCard(
            Icons.cake, "Data de Nascimento", aluno['dataNascimento'] ?? "---"),
        _infoCard(Icons.family_restroom, "Responsável",
            aluno['responsibleName'] ?? "---"),
        _infoCard(
            Icons.badge, "CPF do Responsável", aluno['responsibleCpf'] ?? "---"),
        StreamBuilder<DocumentSnapshot>(
          stream: escolaId != null
              ? FirebaseFirestore.instance
              .collection('escolas')
              .doc(escolaId)
              .snapshots()
              : const Stream.empty(),
          builder: (context, escolaSnapshot) {
            String escolaNome = "---";
            if (escolaSnapshot.hasData && escolaSnapshot.data!.exists) {
              final escolaData =
              escolaSnapshot.data!.data() as Map<String, dynamic>;
              escolaNome = escolaData['nome'] ?? "---";
            }
            return _infoCard(Icons.school, "Escola", escolaNome);
          },
        ),
        if (turmaId != null && escolaId != null)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('escolas')
                .doc(escolaId)
                .collection('turmas')
                .doc(turmaId)
                .snapshots(),
            builder: (context, turmaSnapshot) {
              if (turmaSnapshot.connectionState == ConnectionState.waiting) {
                return _infoCard(Icons.group, "Turma", "Carregando...");
              }
              if (turmaSnapshot.hasData && turmaSnapshot.data!.exists) {
                final turmaData =
                turmaSnapshot.data!.data() as Map<String, dynamic>;
                return _infoCard(Icons.group, "Turma", turmaData['nome'] ?? "---");
              }
              return _infoCard(Icons.group, "Turma", "Não matriculado");
            },
          )
        else
          _infoCard(Icons.group, "Turma", "Não matriculado"),
      ],
    );
  }

  Widget _buildRegistrosList(String tipo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(widget.alunoId)
          .collection('registros')
          .where('tipo', isEqualTo: tipo)
          .orderBy('data', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erro ao carregar os registros: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Nenhum(a) $tipo encontrado(a)."));
        }

        final registros = snapshot.data!.docs;

        return ListView.builder(
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final doc = registros[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['data'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null
                ? DateFormat('dd/MM/yyyy', 'pt_BR').format(timestamp)
                : 'Sem data';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['titulo'] ?? 'Sem Título'),
                subtitle: Text(
                  data['descricao'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(formattedDate),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title:
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}