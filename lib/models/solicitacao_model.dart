class Solicitacao {
  final String id;
  final String tipo;
  final String? descricao;
  final String solicitanteId;
  final DateTime? data;
  final String status;
  final String? resposta;
  final String? equipeId;

  Solicitacao({
    required this.id,
    required this.tipo,
    this.descricao,
    required this.solicitanteId,
    this.data,
    this.status = 'aberto',
    this.resposta,
    this.equipeId,
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'outros',
      descricao: json['descricao']?.toString(),
      solicitanteId: json['solicitante_id']?.toString() ?? '',
      data: json['data'] != null ? DateTime.tryParse(json['data']) : null,
      status: json['status']?.toString() ?? 'aberto',
      resposta: json['resposta']?.toString(),
      equipeId: json['equipe_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'descricao': descricao,
      'solicitante_id': solicitanteId,
      'equipe_id': equipeId,
      'status': status,
      'resposta': resposta,
    };
  }
}
