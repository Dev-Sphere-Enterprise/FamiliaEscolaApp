import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelecionarResponsavelPage extends StatefulWidget {
  final String escolaId;
  const SelecionarResponsavelPage({super.key, required this.escolaId});

  @override
  State<SelecionarResponsavelPage> createState() =>
      _SelecionarResponsavelPageState();
}

class _SelecionarResponsavelPageState extends State<SelecionarResponsavelPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'responsavel')
        .where('escolaId', isEqualTo: widget.escolaId)
        .orderBy('nome')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar responsável'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (txt) => setState(() => _query = txt.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum responsável encontrado'));
                }

                // filtro local pelo nome (evita índices de busca complexos)
                final docs = snap.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['nome'] ?? '').toString().toLowerCase();
                  return _query.isEmpty || name.contains(_query);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhum resultado para a busca'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;

                    final nome = (data['nome'] ?? 'Sem nome').toString();
                    final cpf  = (data['cpf'] ?? '').toString();

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(cpf.isEmpty ? 'Sem CPF' : 'CPF: $cpf'),
                      onTap: () {
                        Navigator.pop<Map<String, dynamic>>(context, {
                          'uid': d.id,
                          'nome': nome,
                          'cpf': cpf,
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
