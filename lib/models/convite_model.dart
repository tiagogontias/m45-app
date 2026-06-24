class Convite {
  final String id;
  final String email;
  final String? teamId;
  final String? token;
  final String status;
  final String? criadoPor;
  final DateTime? createdAt;

  Convite({
    required this.id,
    required this.email,
    this.teamId,
    this.token,
    this.status = 'pendente',
    this.criadoPor,
    this.createdAt,
  });

  factory Convite.fromJson(Map<String, dynamic> json) {
    return Convite(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      teamId: json['team_id']?.toString(),
      token: json['token']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      criadoPor: json['criado_por']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'team_id': teamId,
      'token': token,
      'status': status,
      'criado_por': criadoPor,
    };
  }
}
