import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';
import '../services/sync_service.dart';

class CheckinScreenArgs {
  final String? eventoId;
  final String? eventoNome;

  CheckinScreenArgs({this.eventoId, this.eventoNome});
}

class CheckinScreen extends StatefulWidget {
  final CheckinScreenArgs? args;

  const CheckinScreen({super.key, this.args});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _eventoIdController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args?.eventoId != null) {
      _eventoIdController.text = args!.eventoId!;
    }
  }

  @override
  void dispose() {
    _eventoIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _realizarCheckin() async {
    final eventoId = _eventoIdController.text.trim();
    final token = _tokenController.text.trim();

    if (eventoId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o evento e o token.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final localStorage = GetIt.instance<LocalStorageService>();
      final user = localStorage.getUser();
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Tenta fazer checkin online
      await GetIt.instance<PocketBaseService>().realizarCheckin(
        eventoId,
        token,
        user.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in realizado! +10 pontos'),
          backgroundColor: Colors.green,
        ),
      );
      _tokenController.clear();
    } catch (e) {
      // Se falhou, salva offline
      try {
        final localStorage = GetIt.instance<LocalStorageService>();
        final user = localStorage.getUser();
        if (user != null) {
          await localStorage.savePendingCheckin({
            'eventoId': eventoId,
            'token': token,
            'userId': user.id,
            'offline': true,
            'timestamp': DateTime.now().toIso8601String(),
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sem conexão. Check-in salvo offline e sincronizado depois.'),
              backgroundColor: Colors.orange,
            ),
          );
          _tokenController.clear();
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.args?.eventoNome != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Evento: ${widget.args!.eventoNome!}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            TextField(
              controller: _eventoIdController,
              decoration: const InputDecoration(
                labelText: 'Evento ID',
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token do QR Code',
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _realizarCheckin,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Processando...' : 'Realizar Check-in'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '💡 Dica: No Windows, insira o token manualmente. '
                  'Se estiver sem internet, o check-in será salvo e sincronizado automaticamente quando a conexão for restaurada.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
