class UserModel {
  final String id;
  final String nome;
  final String email;
  final String? codigoIndicacao;
  final String? indicadoPor;
  final String? telefone;
  final String? cidade;
  final String? equipeId;
  final String? coordenadorId;
  final String cargo;
  final String? estado;
  final bool ativo;
  final int pontuacaoTotal;
  final List<String>? areasInteresse;
  final List<Map<String, dynamic>>? candidatosApoio;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.codigoIndicacao,
    this.indicadoPor,
    this.telefone,
    this.cidade,
    this.equipeId,
    this.coordenadorId,
    this.cargo = 'militante',
    this.estado,
    this.ativo = true,
    this.pontuacaoTotal = 0,
    this.areasInteresse,
    this.candidatosApoio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      codigoIndicacao: json['codigo_indicacao']?.toString(),
      indicadoPor: json['indicado_por']?.toString(),
      telefone: json['telefone']?.toString(),
      cidade: json['cidade']?.toString(),
      equipeId: json['equipe_id']?.toString(),
      coordenadorId: json['coordenador_id']?.toString(),
      cargo: json['cargo']?.toString() ?? 'militante',
      estado: json['estado']?.toString(),
      ativo: json['ativo'] as bool? ?? true,
      pontuacaoTotal: (json['pontuacao_total'] as num?)?.toInt() ?? 0,
      areasInteresse: json['areas_interesse'] != null
          ? (json['areas_interesse'] as List).map((e) => e.toString()).toList()
          : null,
      candidatosApoio: json['candidatos_apoio'] != null
          ? (json['candidatos_apoio'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'codigo_indicacao': codigoIndicacao,
      'indicado_por': indicadoPor,
      'telefone': telefone,
      'cidade': cidade,
      'equipe_id': equipeId,
      'coordenador_id': coordenadorId,
      'cargo': cargo,
      'estado': estado,
      'ativo': ativo,
      'pontuacao_total': pontuacaoTotal,
      'areas_interesse': areasInteresse,
      'candidatos_apoio': candidatosApoio,
    };
  }

  bool get isAdmin => cargo == 'super_admin';
  bool get isCoordenadorGeral => cargo == 'coordenador_geral';
  bool get isCoordenadorMunicipal => cargo == 'coordenador_municipal';
  bool get isCoordenador => isCoordenadorGeral || isCoordenadorMunicipal;
  bool get isMilitante => cargo == 'militante';
}
