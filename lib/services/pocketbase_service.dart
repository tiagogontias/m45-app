import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/config.dart';
import '../models/evento_model.dart';
import '../models/mural_post_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/convite_model.dart';
import '../models/atividade_model.dart';

class PocketBaseService {
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        'Content-Type': 'application/json',
      };

  Map<String, String> get _serviceHeaders => {
        'apikey': AppConfig.supabaseServiceKey,
        'Authorization': 'Bearer ${AppConfig.supabaseServiceKey}',
        'Content-Type': 'application/json',
      };

  // ==================== AUTH ====================

  Future<UserModel> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('E-mail ou senha inválidos.');
    }

    final data = jsonDecode(response.body);
    final accessToken = data['access_token'];
    final userId = data['user']['id'];

    // Busca perfil completer
    final profile = await _getUserProfile(userId, accessToken);
    return profile;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String nome,
    String? codigoIndicacao,
  }) async {
    // Verifica código de indicação
    if (codigoIndicacao != null && codigoIndicacao.isNotEmpty) {
      final indicador = await getUserByCode(codigoIndicacao);
      if (indicador == null) {
        throw Exception('Código de indicação inválido.');
      }
    }

    // Cria usuário no Auth
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/auth/v1/signup'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {'nome': nome},
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['msg'] ?? 'Erro ao criar conta.');
    }

    final data = jsonDecode(response.body);
    final userId = data['user']['id'];
    final accessToken = data['session']?['access_token'];

    // Gera código único
    final codigo = await _gerarCodigoUnico();

    // Cria perfil
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles'),
      headers: _serviceHeaders,
      body: jsonEncode({
        'id': userId,
        'nome': nome,
        'email': email,
        'codigo_indicacao': codigo,
        'indicado_por': codigoIndicacao,
        'cargo': 'militante',
        'ativo': true,
        'pontuacao_total': 0,
      }),
    );

    return _getUserProfile(userId, accessToken ?? AppConfig.supabaseAnonKey);
  }

  Future<void> logout() async {
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/auth/v1/logout'),
      headers: _headers,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    // Retorna do cache local (implementado no LocalStorageService)
    return null;
  }

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Usuário não autenticado.');

    await _client.patch(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${user.id}'),
      headers: _serviceHeaders,
      body: jsonEncode(data),
    );
  }

  Future<UserModel?> getUserByCode(String codigo) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?codigo_indicacao=eq.$codigo&select=*'),
      headers: _serviceHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return UserModel.fromJson(data[0]);
      }
    }
    return null;
  }

  Future<UserModel> _getUserProfile(String userId, String token) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return UserModel.fromJson(data[0]);
      }
    }

    // Fallback: retorna dados básicos
    return UserModel(
      id: userId,
      nome: '',
      email: '',
    );
  }

  // ==================== EVENTOS ====================

  Future<List<EventoModel>> getEventos() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/eventos?select=*&order=data.asc'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => EventoModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<EventoModel?> getEvento(String id) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/eventos?id=eq.$id&select=*'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return EventoModel.fromJson(data[0]);
      }
    }
    return null;
  }

  Future<EventoModel> createEvento(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/eventos'),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return EventoModel.fromJson(result[0]);
    }
    throw Exception('Erro ao criar evento.');
  }

  Future<void> confirmarPresenca(String eventoId) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Usuário não autenticado.');

    // Cria checkin
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/checkins'),
      headers: _headers,
      body: jsonEncode({
        'user_id': user.id,
        'evento_id': eventoId,
        'tipo_checkin': 'confirmacao',
        'offline': false,
      }),
    );

    // Incrementa confirmados
    final evento = await getEvento(eventoId);
    if (evento != null) {
      await _client.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/eventos?id=eq.$eventoId'),
        headers: _serviceHeaders,
        body: jsonEncode({'confirmados': evento.confirmados + 1}),
      );
    }

    // Atualiza pontuação (+3)
    await _client.patch(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${user.id}'),
      headers: _serviceHeaders,
      body: jsonEncode({'pontuacao_total': user.pontuacaoTotal + 3}),
    );
  }

  // ==================== RANKING ====================

  Future<List<UserModel>> getRanking() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?select=*&order=pontuacao_total.desc&limit=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  // ==================== MURAL ====================

  Future<List<MuralPostModel>> getMuralPosts() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/mural_posts?select=*&order=data.desc'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => MuralPostModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<MuralPostModel> createMuralPost(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/mural_posts'),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return MuralPostModel.fromJson(result[0]);
    }
    throw Exception('Erro ao criar post.');
  }

  // ==================== CHECKIN ====================

  Future<List<Map<String, dynamic>>> getConvidadosPendentes(String eventoId) async {
    // Busca todos os perfis que NÃO fizeram checkin neste evento
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?select=id,nome,email,telefone&not.id=in.(select user_id from checkins where evento_id=eq.$eventoId)'),
      headers: _serviceHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  Future<String> gerarQrCodeToken(String eventoId) async {
    final random = Random();
    final token = 'M45-$eventoId-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(9999).toString().padLeft(4, '0')}';

    await _client.patch(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/eventos?id=eq.$eventoId'),
      headers: _serviceHeaders,
      body: jsonEncode({'qr_code_token': token}),
    );

    return token;
  }

  Future<void> realizarCheckin(String eventoId, String token, String userId) async {
    if (token.trim().isEmpty) {
      throw Exception('Token inválido.');
    }

    // Verifica token
    final evento = await getEvento(eventoId);
    if (evento != null &&
        evento.qrCodeToken != null &&
        evento.qrCodeToken!.isNotEmpty &&
        evento.qrCodeToken != token) {
      throw Exception('Token não confere com o evento.');
    }

    // Cria checkin
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/checkins'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'evento_id': eventoId,
        'tipo_checkin': 'entrada',
        'token': token,
        'offline': false,
      }),
    );

    // Atualiza pontuação (+10)
    final user = await getUserById(userId);
    if (user != null) {
      await _client.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId'),
        headers: _serviceHeaders,
        body: jsonEncode({'pontuacao_total': user.pontuacaoTotal + 10}),
      );
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*'),
      headers: _serviceHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return UserModel.fromJson(data[0]);
      }
    }
    return null;
  }

  // ==================== CONEXÕES ====================

  Future<void> criarConexao({
    required String conexaoId,
    required String tipo,
    String? eventoId,
  }) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Usuário não autenticado.');

    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/conexoes'),
      headers: _headers,
      body: jsonEncode({
        'user_id': user.id,
        'conexao_id': conexaoId,
        'tipo': tipo,
        'evento_id': eventoId,
      }),
    );
  }

  // ==================== INTERESSES ====================

  Future<void> salvarInteresses({
    required List<String> areas,
    required List<Map<String, dynamic>> candidatosApoio,
  }) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Usuário não autenticado.');

    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/interesses'),
      headers: {..._serviceHeaders, 'Prefer': 'resolution=merge-duplicates'},
      body: jsonEncode({
        'user_id': user.id,
        'areas': areas,
        'candidatos_apoio': candidatosApoio,
      }),
    );
  }

  // ==================== MATERIAIS ====================

  Future<List<Map<String, dynamic>>> getMateriais() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/materiais?select=*&order=created_at.desc'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  // ==================== INDICAÇÕES ====================

  Future<List<UserModel>> getIndicados(String userId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?indicado_por=eq.$userId&select=*'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<int> getIndicacoesConvertidas(String userId) async {
    // Conta quantos indicados pelo userId fizeram check-in
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/checkins?user_id=eq.$userId&select=id'),
      headers: _serviceHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.length;
      }
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getRankingIndicadores() async {
    // Busca todos os perfis e conta indicações convertidas
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?select=*&order=pontuacao_total.desc&limit=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        List<Map<String, dynamic>> ranking = [];
        for (var user in data) {
          final userId = user['id'];
          // Verifica se o usuário foi indicado por alguém
          if (user['indicado_por'] != null && user['indicado_por'].toString().isNotEmpty) {
            // Conta check-ins do indicado para pontuar o indicador
            final checkinsResp = await _client.get(
              Uri.parse('${AppConfig.supabaseUrl}/rest/v1/checkins?user_id=eq.$userId&select=id'),
              headers: _serviceHeaders,
            );
            int indicacoesConvertidas = 0;
            if (checkinsResp.statusCode == 200) {
              final checkins = jsonDecode(checkinsResp.body);
              if (checkins is List && checkins.isNotEmpty) {
                indicacoesConvertidas = 1; // Pelo menos 1 check-in = convertida
              }
            }
            ranking.add({
              ...Map<String, dynamic>.from(user),
              'indicacoes_convertidas': indicacoesConvertidas,
            });
          }
        }
        ranking.sort((a, b) => (b['indicacoes_convertidas'] as int).compareTo(a['indicacoes_convertidas'] as int));
        return ranking;
      }
    }
    return [];
  }

  // ==================== MATCH POR INTERESSES ====================

  Future<List<Map<String, dynamic>>> getMatches(String userId) async {
    // Busca interesses do usuário logado
    final userInteressesResp = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/interesses?user_id=eq.$userId&select=areas'),
      headers: _serviceHeaders,
    );

    List<String> userAreas = [];
    if (userInteressesResp.statusCode == 200) {
      final data = jsonDecode(userInteressesResp.body);
      if (data is List && data.isNotEmpty && data[0]['areas'] != null) {
        userAreas = (data[0]['areas'] as List).map((e) => e.toString()).toList();
      }
    }

    if (userAreas.isEmpty) return [];

    // Busca todos os perfis com interesses
    final allInteressesResp = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/interesses?select=user_id,areas&user_id=neq.$userId'),
      headers: _serviceHeaders,
    );

    List<Map<String, dynamic>> matches = [];
    if (allInteressesResp.statusCode == 200) {
      final data = jsonDecode(allInteressesResp.body);
      if (data is List) {
        for (var item in data) {
          final otherAreas = (item['areas'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final commonAreas = userAreas.where((a) => otherAreas.contains(a)).toList();
          if (commonAreas.isNotEmpty) {
            // Busca dados do perfil
            final profileResp = await _client.get(
              Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${item['user_id']}&select=id,nome,cidade'),
              headers: _serviceHeaders,
            );
            if (profileResp.statusCode == 200) {
              final profileData = jsonDecode(profileResp.body);
              if (profileData is List && profileData.isNotEmpty) {
                matches.add({
                  ...Map<String, dynamic>.from(profileData[0]),
                  'areas_comuns': commonAreas,
                });
              }
            }
          }
        }
      }
    }
    return matches;
  }

  Future<void> criarMatch(String userId, String matchId) async {
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/conexoes'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'conexao_id': matchId,
        'tipo': 'match_trabalho',
      }),
    );
  }

  // ==================== EQUIPES ====================

  Future<List<Team>> getTeams() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/teams?select=*&ativa=eq.true&order=nome'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Team.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<Team> createTeam(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/teams'),
      headers: {..._serviceHeaders, 'Prefer': 'return=representation'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return Team.fromJson(result[0]);
    }
    throw Exception('Erro ao criar equipe.');
  }

  // ==================== CONVITES ====================

  Future<void> enviarConvite({required String email, required String teamId}) async {
    final token = DateTime.now().millisecondsSinceEpoch.toString();
    await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/convites'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'team_id': teamId,
        'token': token,
        'status': 'pendente',
      }),
    );
  }

  // ==================== ATIVIDADES ====================

  Future<List<Atividade>> getAtividades() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/atividades?select=*&order=data.desc'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Atividade.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<Atividade> createAtividade(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/atividades'),
      headers: {..._serviceHeaders, 'Prefer': 'return=representation'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return Atividade.fromJson(result[0]);
    }
    throw Exception('Erro ao criar atividade.');
  }

  // ==================== HELPERS ====================

  Future<String> _gerarCodigoUnico() async {
    final random = Random();
    for (int tentativa = 0; tentativa < 50; tentativa++) {
      final numero = random.nextInt(100000);
      final codigo = '${AppConfig.codigoPrefixo}-${numero.toString().padLeft(5, '0')}';

      final response = await _client.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?codigo_indicacao=eq.$codigo&select=id'),
        headers: _serviceHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isEmpty) {
          return codigo;
        }
      }
    }
    throw Exception('Não foi possível gerar um código único.');
  }
}
