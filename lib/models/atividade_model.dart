class Atividade {
  final String id;
  final String titulo;
  final String? descricao;
  final String? local;
  final DateTime? data;
  final String? horaInicio;
  final String? horaFim;
  final String tipo;
  final String? equipeId;
  final String? coordenadorId;
  final String status;
  final DateTime? createdAt;

  Atividade({
    required this.id,
    required this.titulo,
    this.descricao,
    this.local,
    this.data,
    this.horaInicio,
    this.horaFim,
    this.tipo = 'reuniao',
    this.equipeId,
    this.coordenadorId,
    this.status = 'agendado',
    this.createdAt,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      local: json['local']?.toString(),
      data: json['data'] != null ? DateTime.tryParse(json['data']) : null,
      horaInicio: json['hora_inicio']?.toString(),
      horaFim: json['hora_fim']?.toString(),
      tipo: json['tipo']?.toString() ?? 'reuniao',
      equipeId: json['equipe_id']?.toString(),
      coordenadorId: json['coordenador_id']?.toString(),
      status: json['status']?.toString() ?? 'agendado',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'local': local,
      'data': data?.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'tipo': tipo,
      'equipe_id': equipeId,
      'coordenador_id': coordenadorId,
      'status': status,
    };
  }
}
