class CheckinModel {
  final String id;
  final String userId;
  final String eventoId;
  final String timestamp;
  final String tipoCheckin;
  final Map<String, double>? geolocalizacao;
  final bool offline;

  CheckinModel({
    required this.id,
    required this.userId,
    required this.eventoId,
    required this.timestamp,
    this.tipoCheckin = 'entrada',
    this.geolocalizacao,
    this.offline = false,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      eventoId: json['evento_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      tipoCheckin: json['tipo_checkin'] ?? 'entrada',
      geolocalizacao: json['geolocalizacao'] != null
          ? Map<String, double>.from(json['geolocalizacao'])
          : null,
      offline: json['offline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'evento_id': eventoId,
      'timestamp': timestamp,
      'tipo_checkin': tipoCheckin,
      'geolocalizacao': geolocalizacao,
      'offline': offline,
    };
  }
}
