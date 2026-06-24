class EventoModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String? data;
  final String? horario;
  final String? local;
  final Map<String, double>? geolocalizacao;
  final String? qrCodeToken;
  final String status;
  final String? criadoPor;
  final int confirmados;
  final int metaParticipantes;

  EventoModel({
    required this.id,
    required this.titulo,
    this.descricao,
    this.data,
    this.horario,
    this.local,
    this.geolocalizacao,
    this.qrCodeToken,
    this.status = 'agendado',
    this.criadoPor,
    this.confirmados = 0,
    this.metaParticipantes = 0,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      data: json['data']?.toString(),
      horario: json['horario']?.toString(),
      local: json['local']?.toString(),
      geolocalizacao: json['geolocalizacao'] != null
          ? Map<String, double>.from(json['geolocalizacao'])
          : null,
      qrCodeToken: json['qr_code_token']?.toString(),
      status: json['status']?.toString() ?? 'agendado',
      criadoPor: json['criado_por']?.toString(),
      confirmados: (json['confirmados'] as num?)?.toInt() ?? 0,
      metaParticipantes: (json['meta_participantes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'data': data,
      'horario': horario,
      'local': local,
      'geolocalizacao': geolocalizacao,
      'qr_code_token': qrCodeToken,
      'status': status,
      'criado_por': criadoPor,
      'confirmados': confirmados,
      'meta_participantes': metaParticipantes,
    };
  }
}
