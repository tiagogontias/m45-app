class InteresseModel {
  final String id;
  final List<String> areas;
  final List<Map<String, dynamic>>? candidatosApoio;
  final String? ultimaTrocaCandidato;

  InteresseModel({
    required this.id,
    required this.areas,
    this.candidatosApoio,
    this.ultimaTrocaCandidato,
  });

  factory InteresseModel.fromJson(Map<String, dynamic> json) {
    return InteresseModel(
      id: json['id'] ?? '',
      areas: List<String>.from(json['areas'] ?? []),
      candidatosApoio: json['candidatos_apoio'] != null
          ? List<Map<String, dynamic>>.from(json['candidatos_apoio'])
          : null,
      ultimaTrocaCandidato: json['ultima_troca_candidato'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areas': areas,
      'candidatos_apoio': candidatosApoio,
      'ultima_troca_candidato': ultimaTrocaCandidato,
    };
  }
}
