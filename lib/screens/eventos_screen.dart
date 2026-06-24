import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/routes.dart';
import '../models/evento_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  late Future<List<EventoModel>> _future;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = GetIt.instance<PocketBaseService>().getEventos();
    _user = GetIt.instance<LocalStorageService>().getUser();
  }

  bool get _canCreate {
    final cargo = _user?.cargo.toLowerCase() ?? '';
    return cargo == 'admin' || cargo == 'coordenador';
  }

  Future<void> _refresh() async {
    setState(() => _loadData());
    await _future;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'agendado':
        return Colors.green;
      case 'andamento':
        return Colors.orange;
      case 'finalizado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Future<void> _createEvento() async {
    final titulo = TextEditingController();
    final data = TextEditingController();
    final horario = TextEditingController();
    final local = TextEditingController();
    final descricao = TextEditingController();
    final meta = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Criar Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titulo,
                    decoration: const InputDecoration(labelText: 'Título *')),
                TextField(
                    controller: data,
                    decoration:
                        const InputDecoration(labelText: 'Data (YYYY-MM-DD) *')),
                TextField(
                    controller: horario,
                    decoration:
                        const InputDecoration(labelText: 'Horário (HH:MM)')),
                TextField(
                    controller: local,
                    decoration: const InputDecoration(labelText: 'Local *')),
                TextField(
                    controller: descricao,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 3),
                TextField(
                    controller: meta,
                    decoration:
                        const InputDecoration(labelText: 'Meta participantes'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar')),
          ],
        );
      },
    );

    if (resultado != true) return;

    if (titulo.text.trim().isEmpty ||
        data.text.trim().isEmpty ||
        local.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título, data e local.')),
      );
      return;
    }

    try {
      await GetIt.instance<PocketBaseService>().createEvento({
        'titulo': titulo.text.trim(),
        'data': data.text.trim(),
        'horario': horario.text.trim(),
        'local': local.text.trim(),
        'descricao': descricao.text.trim(),
        'meta_participantes': int.tryParse(meta.text.trim()) ?? 0,
        'status': 'agendado',
        'confirmados': 0,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento criado com sucesso!')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar evento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: _createEvento,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<EventoModel>>(
          future: _future,
          builder: (context, snapshot) {
            final eventos = snapshot.data ?? <EventoModel>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (eventos.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum evento cadastrado.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: eventos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final evento = eventos[index];
                return Card(
                  child: ListTile(
                    title: Text(evento.titulo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data: ${evento.data ?? '---'}'),
                        Text('Local: ${evento.local ?? '---'}'),
                        Row(
                          children: [
                            const Text('Status: '),
                            Chip(
                              label: Text(
                                evento.status.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(evento.status),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.eventoDetalhe,
                        arguments: evento,
                      );
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
