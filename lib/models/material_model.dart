class MaterialModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String? url;
  final String? thumbnailUrl;
  final String tipo;

  MaterialModel({
    required this.id,
    required this.titulo,
    this.descricao,
    this.url,
    this.thumbnailUrl,
    this.tipo = 'pdf',
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      tipo: json['tipo'] ?? 'pdf',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'tipo': tipo,
    };
  }
}
