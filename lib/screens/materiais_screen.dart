import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/pocketbase_service.dart';

class MateriaisScreen extends StatefulWidget {
  const MateriaisScreen({super.key});

  @override
  State<MateriaisScreen> createState() => _MateriaisScreenState();
}

class _MateriaisScreenState extends State<MateriaisScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<PocketBaseService>().getMateriais();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = GetIt.instance<PocketBaseService>().getMateriais();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materiais')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            final materiais = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (materiais.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum material disponível.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: materiais.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final material = materiais[index];
                final categoria = material['categoria'] ?? '';
                final titulo = material['titulo'] ?? '';
                final descricao = material['descricao'] ?? '';
                final arquivoUrl = material['arquivo_url'] ?? '';
                final thumbnail = material['thumbnail'] as String?;

                return Card(
                  child: ListTile(
                    leading: Icon(_getIconForCategoria(categoria)),
                    title: Text(titulo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(descricao),
                        const SizedBox(height: 4),
                        Wrap(
                          children: [
                            Chip(
                              label: Text(categoria.toUpperCase()),
                              backgroundColor: _getColorForCategoria(categoria),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.download),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Abrindo: $arquivoUrl')),
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

  IconData _getIconForCategoria(String categoria) {
    switch (categoria) {
      case 'video':
        return Icons.video_library;
      case 'arte':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'treinamento':
        return Icons.school;
      case 'discurso':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForCategoria(String categoria) {
    switch (categoria) {
      case 'video':
        return Colors.red.shade100;
      case 'arte':
        return Colors.purple.shade100;
      case 'pdf':
        return Colors.orange.shade100;
      case 'treinamento':
        return Colors.blue.shade100;
      case 'discurso':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
