class Team {
  final String id;
  final String nome;
  final String? descricao;
  final String? coordenadorId;
  final String? municipio;
  final bool ativa;
  final DateTime? createdAt;

  Team({
    required this.id,
    required this.nome,
    this.descricao,
    this.coordenadorId,
    this.municipio,
    this.ativa = true,
    this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      coordenadorId: json['coordenador_id']?.toString(),
      municipio: json['municipio']?.toString(),
      ativa: json['ativa'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'coordenador_id': coordenadorId,
      'municipio': municipio,
      'ativa': ativa,
    };
  }
}
