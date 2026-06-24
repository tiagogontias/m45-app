import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<UserModel>> _future;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<PocketBaseService>().getRanking();
    _currentUser = GetIt.instance<LocalStorageService>().getUser();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getRanking();
      _currentUser = GetIt.instance<LocalStorageService>().getUser();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<UserModel>>(
          future: _future,
          builder: (context, snapshot) {
            final ranking = snapshot.data ?? <UserModel>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (ranking.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Ranking indisponível no momento.')),
                ],
              );
            }

            final currentId = _currentUser?.id ?? '';
            final currentIndex = ranking.indexWhere((u) => u.id == currentId);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ranking.length > 100 ? 100 : ranking.length,
              itemBuilder: (context, index) {
                final user = ranking[index];
                final highlight = user.id == currentId;
                return Card(
                  color: highlight ? Theme.of(context).colorScheme.secondary.withOpacity(0.18) : null,
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(user.nome),
                    subtitle: Text('Pontuação: ' + user.pontuacaoTotal.toString()),
                    trailing: highlight ? const Icon(Icons.star, color: Colors.amber) : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
