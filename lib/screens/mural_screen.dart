import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/mural_post_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/pocketbase_service.dart';

class MuralScreen extends StatefulWidget {
  const MuralScreen({super.key});

  @override
  State<MuralScreen> createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {
  late Future<List<MuralPostModel>> _future;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<PocketBaseService>().getMuralPosts();
    _user = GetIt.instance<LocalStorageService>().getUser();
  }

  bool get _canCreate {
    final cargo = _user?.cargo.toLowerCase() ?? '';
    return cargo == 'admin';
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getMuralPosts();
      _user = GetIt.instance<LocalStorageService>().getUser();
    });
    await _future;
  }

  Future<void> _createPost() async {
    final titulo = TextEditingController();
    final texto = TextEditingController();
    final midia = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título')),
                TextField(controller: texto, decoration: const InputDecoration(labelText: 'Texto'), maxLines: 4),
                TextField(controller: midia, decoration: const InputDecoration(labelText: 'Imagem URL (opcional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final user = _user;
      if (user == null) throw Exception('Usuário não autenticado.');
      await GetIt.instance<PocketBaseService>().createMuralPost({
        'autor_id': user.id,
        'titulo': titulo.text.trim(),
        'texto': texto.text.trim(),
        'midia_url': midia.text.trim(),
        'curtidas': <String>[],
        'data': DateTime.now().toIso8601String(),
      });
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post publicado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao publicar post.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural'),
        actions: [
          if (_canCreate)
            IconButton(
              onPressed: _createPost,
              icon: const Icon(Icons.add),
              tooltip: 'Novo post',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MuralPostModel>>(
          future: _future,
          builder: (context, snapshot) {
            final posts = snapshot.data ?? <MuralPostModel>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (posts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum post no mural.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(post.texto ?? ''),
                        if (post.midiaUrl != null && post.midiaUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.midiaUrl!,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text('Data: ' + post.data, style: const TextStyle(color: Colors.grey)),
                      ],
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
