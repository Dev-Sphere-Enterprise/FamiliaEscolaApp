import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
      if (mounted) setState(() => _loadingPermission = false);
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

  Future<void> _alterarStatusOcorrencia(
      String registroId, String novoStatus) async {
    // ... (código para alterar status da ocorrência)
  }

  void _editarAluno(
      BuildContext context, String alunoId, Map<String, dynamic> aluno) {
    final nomeCtrl = TextEditingController(text: aluno['nome'] ?? "");
    final respNomeCtrl =
        TextEditingController(text: aluno['responsibleName'] ?? "");
    final respCpfCtrl =
        TextEditingController(text: aluno['responsibleCpf'] ?? "");

    // Trata tanto Timestamp quanto String para a data de nascimento
    String nascimentoStr = "";
    final nascimento = aluno['dataNascimento'];
    if (nascimento is Timestamp) {
      final dt = nascimento.toDate();
      nascimentoStr =
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } else if (nascimento is String) {
      nascimentoStr = nascimento;
    }
    final nascimentoCtrl = TextEditingController(text: nascimentoStr);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Aluno"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome do Aluno")),
              TextField(controller: nascimentoCtrl, decoration: const InputDecoration(labelText: "Data de Nascimento")),
              TextField(controller: respNomeCtrl, decoration: const InputDecoration(labelText: "Nome do Responsável")),
              TextField(controller: respCpfCtrl, decoration: const InputDecoration(labelText: "CPF do Responsável")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .update({
                "nome": nomeCtrl.text.trim(),
                "dataNascimento": nascimentoCtrl.text.trim(),
                "responsibleName": respNomeCtrl.text.trim(),
                "responsibleCpf": respCpfCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _excluirAluno(BuildContext context, String alunoId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Aluno"),
        content: const Text("Tem certeza que deseja excluir este aluno?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("students")
                  .doc(alunoId)
                  .delete();
              Navigator.pop(context); // fecha o dialog
              Navigator.pop(context); // volta da tela de detalhes
            },
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
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
          ? SpeedDial(
              icon: Icons.more_vert,
              activeIcon: Icons.close,
              backgroundColor: Colors.blue.shade700,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.add_comment),
                  label: "Adicionar Registro",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdicionarRegistroAlunoPage(
                          alunoId: widget.alunoId,
                        ),
                      ),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.edit),
                  label: "Editar Aluno",
                  onTap: () async {
                    final alunoDoc = await FirebaseFirestore.instance
                        .collection("students")
                        .doc(widget.alunoId)
                        .get();
                    if (alunoDoc.exists && mounted) {
                      _editarAluno(context, widget.alunoId,
                          alunoDoc.data() as Map<String, dynamic>);
                    }
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.delete, color: Colors.red),
                  label: "Excluir Aluno",
                  onTap: () => _excluirAluno(context, widget.alunoId),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildInfoTab(Map<String, dynamic> aluno) {
    final escolaId = aluno['escolaId'];
    final turmaId = aluno['turmaId'];
    
    // Formata a data de nascimento para exibição, seja Timestamp ou String
    String nascimentoStr = "---";
    final nascimento = aluno['dataNascimento'];
    if (nascimento is Timestamp) {
      final dt = nascimento.toDate();
      nascimentoStr =
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } else if (nascimento is String) {
      nascimentoStr = nascimento;
    }

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
        _infoCard(Icons.cake, "Data de Nascimento", nascimentoStr),
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
                return _infoCard(
                    Icons.group, "Turma", turmaData['nome'] ?? "---");
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
    // Este método permanece o mesmo, sem alterações.
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
            final status = data['status'];
            final bool isPendente = status == 'Pendente';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['titulo'] ?? 'Sem Título'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['descricao'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tipo == 'Ocorrência' && status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Chip(
                          label: Text(status,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: isPendente
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          avatar: Icon(
                            isPendente
                                ? Icons.hourglass_top
                                : Icons.check_circle,
                            color: isPendente
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: _ehGestor && isPendente && tipo == 'Ocorrência'
                    ? ElevatedButton(
                        onPressed: () =>
                            _alterarStatusOcorrencia(doc.id, 'Resolvido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Resolver'),
                      )
                    : null,
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
