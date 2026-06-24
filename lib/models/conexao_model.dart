class ConexaoModel {
  final String id;
  final String userId;
  final String conexaoId;
  final String tipo;
  final String? eventoId;
  final String data;

  ConexaoModel({
    required this.id,
    required this.userId,
    required this.conexaoId,
    required this.tipo,
    this.eventoId,
    required this.data,
  });

  factory ConexaoModel.fromJson(Map<String, dynamic> json) {
    return ConexaoModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      conexaoId: json['conexao_id'] ?? '',
      tipo: json['tipo'] ?? '',
      eventoId: json['evento_id'],
      data: json['data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'conexao_id': conexaoId,
      'tipo': tipo,
      'evento_id': eventoId,
      'data': data,
    };
  }
}
