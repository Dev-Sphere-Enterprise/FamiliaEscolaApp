import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  final String escolaId;

  const DashboardPage({super.key, required this.escolaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard da Escola",
          style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Visão Geral da Escola",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cards de Resumo
            const Text(
              "📊 Indicadores Gerais",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            _buildResumoCards(),

            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 32),

            // Gráfico de Alunos por Turma
            const Text(
              "👩‍🎓 Distribuição de Alunos por Turma",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            _buildAlunosPorTurma(),

            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 32),

            // Gráfico de Avisos por Mês
            const Text(
              "📢 Avisos Publicados por Mês",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            _buildAvisosPorMes(),

            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 32),

            // Atividade no Fórum
            const Text(
              "💬 Atividade no Fórum",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            _buildForumAtividade(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------- CARDS RESUMO ----------
  Widget _buildResumoCards() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Erro ao carregar dados",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final data = snapshot.data ?? {};
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildCard("Alunos", data['Alunos'] ?? 0, Icons.people, const Color(0xFF00A74F)),
            _buildCard("Turmas", data['Turmas'] ?? 0, Icons.class_, const Color(0xFF4299E1)),
            _buildCard("Avisos", data['Avisos'] ?? 0, Icons.announcement, const Color(0xFFED8936)),
            _buildCard("Conversas", data['Conversas'] ?? 0, Icons.chat, const Color(0xFF9F7AEA)),
            _buildCard("Tópicos", data['Tópicos Fórum'] ?? 0, Icons.forum, const Color(0xFF48BB78)),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _fetchCounts() async {
    final db = FirebaseFirestore.instance;

    final alunos = await db.collection('students').where('escolaId', isEqualTo: escolaId).get();
    final turmas = await db.collection('escolas').doc(escolaId).collection('turmas').get();
    final avisos = await db.collection('avisos').where('escolaId', isEqualTo: escolaId).get();
    final conversas = await db.collection('escolas').doc(escolaId).collection('conversas').get();
    final forum = await db.collection('escolas').doc(escolaId).collection('forum').get();

    return {
      'Alunos': alunos.size,
      'Turmas': turmas.size,
      'Avisos': avisos.size,
      'Conversas': conversas.size,
      'Tópicos Fórum': forum.size,
    };
  }

  Widget _buildCard(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- GRÁFICO DE PIZZA: Alunos por Turma ----------
  Widget _buildAlunosPorTurma() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("students")
          .where("escolaId", isEqualTo: escolaId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Nenhum aluno cadastrado",
                style: TextStyle(color: Color(0xFF718096)),
              ),
            ),
          );
        }

        final alunos = snapshot.data!.docs;
        final Map<String, int> porTurma = {};
        for (var doc in alunos) {
          final data = doc.data() as Map<String, dynamic>;
          final turmaId = data['turmaId'] ?? "Sem turma";
          porTurma[turmaId] = (porTurma[turmaId] ?? 0) + 1;
        }

        // 🔹 Buscar nomes das turmas
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("escolas")
              .doc(escolaId)
              .collection("turmas")
              .get(),
          builder: (context, turmaSnapshot) {
            if (!turmaSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final turmasDocs = turmaSnapshot.data!.docs;
            final Map<String, String> turmaNomes = {
              for (var t in turmasDocs)
                t.id: (t.data() as Map<String, dynamic>)['nome'] ?? t.id
            };

            final colors = [
              const Color(0xFF00A74F),
              const Color(0xFF4299E1),
              const Color(0xFFED8936),
              const Color(0xFF9F7AEA),
              const Color(0xFF48BB78),
              const Color(0xFFF56565),
            ];

            final sections = porTurma.entries.map((entry) {
              final index = porTurma.keys.toList().indexOf(entry.key);
              final nome = entry.key == "Sem turma"
                  ? "Sem turma"
                  : turmaNomes[entry.key] ?? entry.key;

              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: nome,
                color: colors[index % colors.length],
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            }).toList();

            return Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- GRÁFICO DE BARRAS: Avisos por mês ----------
  Widget _buildAvisosPorMes() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("avisos")
          .where("escolaId", isEqualTo: escolaId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Nenhum aviso publicado",
                style: TextStyle(color: Color(0xFF718096)),
              ),
            ),
          );
        }

        final avisos = snapshot.data!.docs;
        final Map<String, int> porMes = {};
        for (var doc in avisos) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data["data"] as Timestamp?;
          if (ts != null) {
            final date = ts.toDate();
            final mes = DateFormat("MM/yyyy").format(date);
            porMes[mes] = (porMes[mes] ?? 0) + 1;
          }
        }

        final barGroups = porMes.entries.map((entry) {
          final index = porMes.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: const Color(0xFF00A74F),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        }).toList();

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < porMes.keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            porMes.keys.elementAt(index),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        );
      },
    );
  }

  // ---------- GRÁFICO DE LINHA: Atividade no Fórum ----------
  Widget _buildForumAtividade() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("escolas")
          .doc(escolaId)
          .collection("forum")
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Nenhuma atividade no fórum",
                style: TextStyle(color: Color(0xFF718096)),
              ),
            ),
          );
        }

        final topicos = snapshot.data!.docs;
        final Map<String, int> porDia = {};
        for (var doc in topicos) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data["criadoEm"] as Timestamp?;
          if (ts != null) {
            final date = ts.toDate();
            final dia = DateFormat("dd/MM").format(date);
            porDia[dia] = (porDia[dia] ?? 0) + 1;
          }
        }

        final spots = porDia.entries.map((entry) {
          final index = porDia.keys.toList().indexOf(entry.key);
          return FlSpot(index.toDouble(), entry.value.toDouble());
        }).toList();

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < porDia.keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            porDia.keys.elementAt(index),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  color: const Color(0xFF00A74F),
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: const Color(0xFF00A74F).withOpacity(0.1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}