class MuralPostModel {
  final String id;
  final String autorId;
  final String titulo;
  final String? texto;
  final String? midiaUrl;
  final List<String> curtidas;
  final String data;

  MuralPostModel({
    required this.id,
    required this.autorId,
    required this.titulo,
    this.texto,
    this.midiaUrl,
    this.curtidas = const [],
    required this.data,
  });

  factory MuralPostModel.fromJson(Map<String, dynamic> json) {
    return MuralPostModel(
      id: json['id'] ?? '',
      autorId: json['autor_id'] ?? '',
      titulo: json['titulo'] ?? '',
      texto: json['texto'],
      midiaUrl: json['midia_url'],
      curtidas: json['curtidas'] != null
          ? List<String>.from(json['curtidas'])
          : [],
      data: json['data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autor_id': autorId,
      'titulo': titulo,
      'texto': texto,
      'midia_url': midiaUrl,
      'curtidas': curtidas,
      'data': data,
    };
  }
}
