import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/routes.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';
import '../shared/widgets/error_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final localStorage = GetIt.instance<LocalStorageService>();
    final user = localStorage.getUser();
    if (user != null) {
      setState(() => _user = user);
    }
  }

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) return;

    final nome = TextEditingController(text: user.nome);
    final telefone = TextEditingController(text: user.telefone ?? '');
    final interesses =
        TextEditingController(text: (user.areasInteresse ?? []).join(', '));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nome,
                    decoration: const InputDecoration(labelText: 'Nome')),
                TextField(
                    controller: telefone,
                    decoration: const InputDecoration(labelText: 'Telefone')),
                TextField(
                    controller: interesses,
                    decoration: const InputDecoration(
                        labelText: 'Interesses (separados por vírgula)'),
                    maxLines: 3),
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final areasList = interesses.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Atualiza no PocketBase
      await GetIt.instance<PocketBaseService>().saveUserProfile({
        'nome': nome.text.trim(),
        'telefone': telefone.text.trim(),
        'areas_interesse': areasList,
      });

      // Salva interesses
      await GetIt.instance<PocketBaseService>().salvarInteresses(
        areas: areasList,
        candidatosApoio: user.candidatosApoio ?? [],
      );

      // Atualiza local
      final updatedUser = UserModel(
        id: user.id,
        nome: nome.text.trim(),
        email: user.email,
        codigoIndicacao: user.codigoIndicacao,
        indicadoPor: user.indicadoPor,
        telefone: telefone.text.trim(),
        cidade: user.cidade,
        equipeId: user.equipeId,
        cargo: user.cargo,
        ativo: user.ativo,
        pontuacaoTotal: user.pontuacaoTotal,
        areasInteresse: areasList,
        candidatosApoio: user.candidatosApoio,
      );

      await GetIt.instance<LocalStorageService>().saveUser(updatedUser);
      if (!mounted) return;
      setState(() => _user = updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
    } catch (e) {
      if (!mounted) return;
      await ErrorDialog.show(context, 'Erro ao atualizar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      final pb = GetIt.instance<PocketBaseService>();
      final localStorage = GetIt.instance<LocalStorageService>();
      await pb.logout();
      await localStorage.clearUser();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await ErrorDialog.show(context, 'Erro ao sair.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Perfil',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user != null && user.nome.isNotEmpty
                      ? user.nome.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _infoCard('Nome', user?.nome ?? '---'),
            _infoCard('Código M45', user?.codigoIndicacao ?? '---'),
            _infoCard('Pontuação', '${user?.pontuacaoTotal ?? 0} pts'),
            _infoCard('Equipe', user?.equipeId ?? '---'),
            _infoCard('Cargo', user?.cargo ?? '---'),
            _infoCard('Áreas de interesse',
                (user?.areasInteresse ?? []).join(', ')),
            _infoCard('Candidatos apoiados', _candidatosTexto(user)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Sair',
                  style: TextStyle(
                      color: _isLoading ? Colors.grey : Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _candidatosTexto(UserModel? user) {
    final candidatos = user?.candidatosApoio ?? [];
    if (candidatos.isEmpty) return '---';
    return candidatos
        .map((item) => (item['nome'] ?? item['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  Widget _infoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
