import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/evento_model.dart';
import '../models/atividade_model.dart';
import '../services/pocketbase_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filtro = 'todos';

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<PocketBaseService>().getAgenda();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getAgenda();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filtro = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
              const PopupMenuItem(value: 'eventos', child: Text('Eventos')),
              const PopupMenuItem(value: 'atividades', child: Text('Atividades')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            var items = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_filtro == 'eventos') {
              items = items.where((i) => i['tipo_item'] == 'evento').toList();
            } else if (_filtro == 'atividades') {
              items = items.where((i) => i['tipo_item'] == 'atividade').toList();
            }

            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum item na agenda.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isEvento = item['tipo_item'] == 'evento';
                final titulo = item['titulo'] ?? '';
                final data = item['data'] ?? '';
                final horario = item['horario'] ?? item['hora_inicio'] ?? '';
                final local = item['local'] ?? '';
                final tipo = item['tipo'] ?? '';

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isEvento ? Icons.event : Icons.assignment,
                      color: isEvento ? Colors.blue : Colors.orange,
                    ),
                    title: Text(titulo),
                    subtitle: Text('$data ${horario.isNotEmpty ? "• $horario" : ""} • $local'),
                    trailing: isEvento
                        ? null
                        : Chip(
                            label: Text(tipo.replaceAll('_', ' ')),
                            backgroundColor: Colors.orange.shade100,
                          ),
                    onTap: () {
                      if (isEvento) {
                        final evento = EventoModel.fromJson(item);
                        Navigator.pushNamed(context, '/evento-detalhe', arguments: evento);
                      }
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
