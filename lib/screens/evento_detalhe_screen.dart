import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../core/config.dart';
import '../core/routes.dart';
import '../models/evento_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';
import 'checkin_screen.dart';

class EventoDetalheScreen extends StatefulWidget {
  final EventoModel evento;

  const EventoDetalheScreen({super.key, required this.evento});

  @override
  State<EventoDetalheScreen> createState() => _EventoDetalheScreenState();
}

class _EventoDetalheScreenState extends State<EventoDetalheScreen> {
  late EventoModel _evento;
  UserModel? _user;
  List<Map<String, dynamic>> _pendentes = [];
  bool _confirmed = false;
  bool _loadingPendentes = false;
  String? _qrToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _evento = widget.evento;
    _user = GetIt.instance<LocalStorageService>().getUser();
    _loadPendentes();
  }

  bool get _canModerate {
    final cargo = _user?.cargo.toLowerCase() ?? '';
    return cargo == 'admin' || cargo == 'coordenador';
  }

  bool get _isAdmin {
    return (_user?.cargo.toLowerCase() ?? '') == 'admin';
  }

  Future<void> _loadPendentes() async {
    if (!_canModerate) return;
    setState(() => _loadingPendentes = true);
    try {
      final list = await GetIt.instance<PocketBaseService>()
          .getConvidadosPendentes(_evento.id);
      if (!mounted) return;
      setState(() => _pendentes = list);
    } finally {
      if (mounted) setState(() => _loadingPendentes = false);
    }
  }

  Future<void> _confirmarPresenca() async {
    setState(() => _isLoading = true);
    try {
      await GetIt.instance<PocketBaseService>().confirmarPresenca(_evento.id);
      if (!mounted) return;
      setState(() => _confirmed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presença confirmada! +3 pontos')),
      );
      // Atualiza dados do usuário
      final updatedUser =
          await GetIt.instance<PocketBaseService>().getCurrentUser();
      if (updatedUser != null && mounted) {
        await GetIt.instance<LocalStorageService>().saveUser(updatedUser);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _gerarQrCode() async {
    setState(() => _isLoading = true);
    try {
      final token = await GetIt.instance<PocketBaseService>()
          .gerarQrCodeToken(_evento.id);
      if (!mounted) return;
      setState(() => _qrToken = token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code gerado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar QR: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copiarConvite() async {
    final codigo = _user?.codigoIndicacao ?? '';
    final link =
        'https://app.m45.com/i/$codigo?evento=${_evento.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link de convite copiado!')),
    );
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

  @override
  Widget build(BuildContext context) {
    final evento = _evento;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do Evento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card principal do evento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Data: ${evento.data ?? '---'}'),
                  Text('Horário: ${evento.horario ?? '---'}'),
                  Text('Local: ${evento.local ?? '---'}'),
                  Row(
                    children: [
                      const Text('Status: '),
                      Chip(
                        label: Text(
                          evento.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(evento.status),
                      ),
                    ],
                  ),
                  if (evento.criadoPor != null)
                    Text('Criado por: ${evento.criadoPor}'),
                  Text('Confirmados: ${evento.confirmados}'),
                  if (evento.metaParticipantes > 0)
                    Text('Meta: ${evento.metaParticipantes} participantes'),
                  const SizedBox(height: 8),
                  if (evento.descricao != null && evento.descricao!.isNotEmpty)
                    Text(evento.descricao!),
                  const SizedBox(height: 16),
                  // Botão Confirmar Presença
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmed || _isLoading
                          ? null
                          : _confirmarPresenca,
                      child: Text(
                          _confirmed ? 'Presença confirmada ✓' : 'Confirmar Presença'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botão Convidar Amigo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _copiarConvite,
                      child: const Text('Convidar Amigo'),
                    ),
                  ),
                  if (_qrToken != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      'Token QR: $_qrToken',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Seção Admin/Coordenador
          if (_canModerate) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Convidados pendentes (${_pendentes.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _gerarQrCode,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Gerar QR Code'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingPendentes)
                      const Center(child: CircularProgressIndicator())
                    else if (_pendentes.isEmpty)
                      const Text('Nenhum convidado pendente.')
                    else
                      Column(
                        children: _pendentes.map((item) {
                          final nome = (item['nome'] ?? 'Sem nome').toString();
                          final contato =
                              (item['telefone'] ?? item['email'] ?? '')
                                  .toString();
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_outline),
                            title: Text(nome),
                            subtitle: Text(contato),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Atalho para Check-in
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Check-in manual'),
              subtitle: const Text(
                  'Abra a tela de check-in para simular a leitura do QR'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.checkin,
                  arguments: CheckinScreenArgs(
                    eventoId: evento.id,
                    eventoNome: evento.titulo,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
