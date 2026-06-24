import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/user_model.dart';
import '../services/pocketbase_service.dart';

class RankingIndicadoresScreen extends StatefulWidget {
  const RankingIndicadoresScreen({super.key});

  @override
  State<RankingIndicadoresScreen> createState() => _RankingIndicadoresScreenState();
}

class _RankingIndicadoresScreenState extends State<RankingIndicadoresScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRanking();
  }

  Future<List<Map<String, dynamic>>> _loadRanking() async {
    final pb = GetIt.instance<PocketBaseService>();
    return await pb.getRankingIndicadores();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadRanking();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Indicações'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final ranking = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ranking.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Nenhuma indicação convertida ainda.')),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final item = ranking[index];
              final nome = item['nome'] ?? 'Sem nome';
              final indicacoes = item['indicacoes_convertidas'] ?? 0;
              final pontuacao = item['pontuacao_total'] ?? 0;
              final codigo = item['codigo_indicacao'] ?? '';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                    backgroundColor: index < 3
                        ? Colors.amber
                        : Colors.grey.shade300,
                  ),
                  title: Text(nome),
                  subtitle: Text('Código: $codigo'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$indicacoes indicações',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('$pontuacao pts'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
