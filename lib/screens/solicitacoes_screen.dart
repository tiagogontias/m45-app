import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/solicitacao_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class SolicitacoesScreen extends StatefulWidget {
  const SolicitacoesScreen({super.key});

  @override
  State<SolicitacoesScreen> createState() => _SolicitacoesScreenState();
}

class _SolicitacoesScreenState extends State<SolicitacoesScreen> {
  late Future<List<Solicitacao>> _future;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _future = GetIt.instance<PocketBaseService>().getMinhasSolicitacoes();
  }

  void _loadUser() {
    final user = GetIt.instance<LocalStorageService>().getUser();
    setState(() => _user = user);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getMinhasSolicitacoes();
    });
    await _future;
  }

  Future<void> _novaSolicitacao() async {
    final tipo = TextEditingController();
    final descricao = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Solicitação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  value: 'combustivel',
                  items: const [
                    DropdownMenuItem(value: 'combustivel', child: Text('Combustível')),
                    DropdownMenuItem(value: 'material_grafico', child: Text('Material Gráfico')),
                    DropdownMenuItem(value: 'adesivos', child: Text('Adesivos')),
                    DropdownMenuItem(value: 'faixas', child: Text('Faixas')),
                    DropdownMenuItem(value: 'transporte', child: Text('Transporte')),
                    DropdownMenuItem(value: 'reuniao', child: Text('Reunião')),
                    DropdownMenuItem(value: 'outros', child: Text('Outros')),
                  ],
                  onChanged: (v) => tipo.text = v ?? 'combustivel',
                ),
                TextField(
                  controller: descricao,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await GetIt.instance<PocketBaseService>().createSolicitacao({
        'tipo': tipo.text,
        'descricao': descricao.text.trim(),
        'solicitante_id': _user?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada!')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aprovado':
        return Colors.green;
      case 'recusado':
        return Colors.red;
      case 'em_analise':
        return Colors.orange;
      case 'concluido':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'aprovado':
        return 'Aprovado';
      case 'recusado':
        return 'Recusado';
      case 'em_analise':
        return 'Em Análise';
      case 'concluido':
        return 'Concluído';
      default:
        return 'Aberto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Solicitações')),
      floatingActionButton: FloatingActionButton(
        onPressed: _novaSolicitacao,
        child: const Icon(Icons.add),
        tooltip: 'Nova Solicitação',
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Solicitacao>>(
          future: _future,
          builder: (context, snapshot) {
            final solicitacoes = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (solicitacoes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhuma solicitação.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: solicitacoes.length,
              itemBuilder: (context, index) {
                final s = solicitacoes[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.assignment, color: _getStatusColor(s.status)),
                    title: Text(s.tipo.replaceAll('_', ' ').toUpperCase()),
                    subtitle: Text(s.descricao ?? ''),
                    trailing: Chip(
                      label: Text(
                        _getStatusLabel(s.status),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(s.status),
                    ),
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
