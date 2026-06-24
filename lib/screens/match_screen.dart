import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  UserModel? _user;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final localStorage = GetIt.instance<LocalStorageService>();
    final user = localStorage.getUser();
    if (user != null) {
      setState(() => _user = user);
      final matches = await GetIt.instance<PocketBaseService>().getMatches(user.id);
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _criarMatch(String matchId) async {
    final user = _user;
    if (user == null) return;

    try {
      await GetIt.instance<PocketBaseService>().criarMatch(user.id, matchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conexão solicitada com sucesso!')),
      );
      // Remove o match da lista
      setState(() {
        _matches.removeWhere((m) => m['id'] == matchId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match por Interesses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum match encontrado ainda.\nEdite seus interesses no perfil para encontrar pessoas com interesses em comum!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final nome = match['nome'] ?? 'Sem nome';
                    final cidade = match['cidade'] ?? '';
                    final areasComuns = match['areas_comuns'] as List? ?? [];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(nome.isNotEmpty
                                      ? nome.substring(0, 1).toUpperCase()
                                      : '?'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (cidade.isNotEmpty)
                                        Text(
                                          cidade,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: areasComuns.map((area) {
                                return Chip(
                                  label: Text(area.toString()),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _criarMatch(match['id']),
                                icon: const Icon(Icons.connect_without_contact),
                                label: const Text('Quero Contato'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
