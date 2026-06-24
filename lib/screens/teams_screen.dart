import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<List<Team>> _future;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _future = GetIt.instance<PocketBaseService>().getTeams();
  }

  void _loadUser() {
    final user = GetIt.instance<LocalStorageService>().getUser();
    setState(() => _user = user);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getTeams();
    });
    await _future;
  }

  Future<void> _criarEquipe() async {
    final nome = TextEditingController();
    final descricao = TextEditingController();
    final municipio = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Criar Equipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da Equipe')),
                TextField(controller: descricao, decoration: const InputDecoration(labelText: 'Descrição')),
                TextField(controller: municipio, decoration: const InputDecoration(labelText: 'Município')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Criar')),
          ],
        );
      },
    );

    if (confirm != true || nome.text.trim().isEmpty) return;

    try {
      await GetIt.instance<PocketBaseService>().createTeam({
        'nome': nome.text.trim(),
        'descricao': descricao.text.trim(),
        'municipio': municipio.text.trim(),
        'coordenador_id': _user?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipe criada!')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin == true || _user?.isCoordenador == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipes'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: _criarEquipe,
              icon: const Icon(Icons.add),
              tooltip: 'Criar Equipe',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Team>>(
          future: _future,
          builder: (context, snapshot) {
            final teams = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (teams.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhuma equipe cadastrada.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(team.nome.substring(0, 1).toUpperCase())),
                    title: Text(team.nome),
                    subtitle: Text(team.municipio ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Ver detalhes da equipe
                    },
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
