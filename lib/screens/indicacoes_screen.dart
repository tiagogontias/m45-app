import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class IndicacoesScreen extends StatefulWidget {
  const IndicacoesScreen({super.key});

  @override
  State<IndicacoesScreen> createState() => _IndicacoesScreenState();
}

class _IndicacoesScreenState extends State<IndicacoesScreen> {
  UserModel? _user;
  List<UserModel> _indicados = [];
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
      final indicados = await GetIt.instance<PocketBaseService>().getIndicados(user.id);
      setState(() {
        _indicados = indicados;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copiarLink() async {
    final codigo = _user?.codigoIndicacao ?? '';
    final link = 'https://app.m45.com/i/$codigo';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link de convite copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codigo = _user?.codigoIndicacao ?? '---';

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Indicações')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card com código de indicação
                  Card(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Seu código de indicação',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            codigo,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _copiarLink,
                            icon: const Icon(Icons.share),
                            label: const Text('Convidar Amigo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pessoas que você indicou (${_indicados.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_indicados.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Ninguém usou seu código ainda.\nCompartilhe o link!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _indicados.map((indicado) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(indicado.nome.isNotEmpty
                                  ? indicado.nome.substring(0, 1).toUpperCase()
                                  : '?'),
                            ),
                            title: Text(indicado.nome),
                            subtitle: Text(indicado.email),
                            trailing: indicado.pontuacaoTotal > 0
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.hourglass_empty, color: Colors.orange),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}
