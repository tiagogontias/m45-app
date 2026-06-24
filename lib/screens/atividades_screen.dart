import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/atividade_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  late Future<List<Atividade>> _future;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _future = GetIt.instance<PocketBaseService>().getAtividades();
  }

  void _loadUser() {
    final user = GetIt.instance<LocalStorageService>().getUser();
    setState(() => _user = user);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getAtividades();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin == true || _user?.isCoordenador == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () {
                // Criar atividade
              },
              icon: const Icon(Icons.add),
              tooltip: 'Nova Atividade',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Atividade>>(
          future: _future,
          builder: (context, snapshot) {
            final atividades = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (atividades.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhuma atividade cadastrada.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: atividades.length,
              itemBuilder: (context, index) {
                final atividade = atividades[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_getIconForTipo(atividade.tipo)),
                    title: Text(atividade.titulo),
                    subtitle: Text('${atividade.local ?? ''} • ${atividade.status}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForTipo(String tipo) {
    switch (tipo) {
      case 'bandeiraco':
        return Icons.flag;
      case 'panfletagem':
        return Icons.description;
      case 'reuniao':
        return Icons.groups;
      case 'mobilizacao':
        return Icons.campaign;
      case 'adesivagem':
        return Icons.car_rental;
      default:
        return Icons.event;
    }
  }
}
