import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/routes.dart';
import '../models/evento_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<EventoModel>> _eventosFuture;
  UserModel? _user;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _eventosFuture = GetIt.instance<PocketBaseService>().getEventos();
    _user = GetIt.instance<LocalStorageService>().getUser();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _eventosFuture;
  }

  EventoModel? _getProximoEvento(List<EventoModel> eventos) {
    final now = DateTime.now();
    final futuros = eventos.where((e) {
      if (e.data == null) return false;
      try {
        final dataEvento = DateTime.parse(e.data!);
        return dataEvento.isAfter(now) && e.status != 'finalizado';
      } catch (_) {
        return false;
      }
    }).toList();
    if (futuros.isEmpty) return eventos.isNotEmpty ? eventos.first : null;
    futuros.sort((a, b) => a.data!.compareTo(b.data!));
    return futuros.first;
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        // Já está na home
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.eventos);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.mural);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M45'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildScoreCard(context),
            const SizedBox(height: 16),
            _buildProximoEventoCard(context),
            const SizedBox(height: 16),
            Text(
              'Atalhos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildShortcutsGrid(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Mural',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final user = _user;
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                user != null && user.nome.isNotEmpty
                    ? user.nome.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá${user != null ? ', ${user.nome}' : ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('Pontuação: ${user?.pontuacaoTotal ?? 0} pts'),
                  Text('Código: ${user?.codigoIndicacao ?? '---'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximoEventoCard(BuildContext context) {
    return FutureBuilder<List<EventoModel>>(
      future: _eventosFuture,
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? <EventoModel>[];
        final proximo = _getProximoEvento(eventos);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo evento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (proximo == null)
                  const Text('Nenhum evento cadastrado ainda.')
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proximo.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Data: ${proximo.data ?? '---'}'),
                      Text('Local: ${proximo.local ?? '---'}'),
                      Text('Status: ${proximo.status}'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.eventoDetalhe,
                              arguments: proximo,
                            );
                          },
                          child: const Text('Ver detalhes'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortcutsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _shortcutCard(
          context,
          icon: Icons.event,
          title: 'Eventos',
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventos),
        ),
        _shortcutCard(
          context,
          icon: Icons.qr_code_scanner,
          title: 'Check-in',
          onTap: () => Navigator.pushNamed(context, AppRoutes.checkin),
        ),
        _shortcutCard(
          context,
          icon: Icons.collections_bookmark,
          title: 'Materiais',
          onTap: () => Navigator.pushNamed(context, AppRoutes.materiais),
        ),
        _shortcutCard(
          context,
          icon: Icons.leaderboard,
          title: 'Ranking',
          onTap: () => Navigator.pushNamed(context, AppRoutes.ranking),
        ),
      ],
    );
  }

  Widget _shortcutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
