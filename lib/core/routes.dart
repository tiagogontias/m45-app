import 'package:flutter/material.dart';

import '../models/evento_model.dart';
import '../screens/checkin_screen.dart';
import '../screens/evento_detalhe_screen.dart';
import '../screens/eventos_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mural_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/register_screen.dart';
import '../screens/teams_screen.dart';
import '../screens/atividades_screen.dart';
import '../screens/materiais_screen.dart';
import '../screens/solicitacoes_screen.dart';
import '../screens/agenda_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String eventos = '/eventos';
  static const String eventoDetalhe = '/evento-detalhe';
  static const String checkin = '/checkin';
  static const String ranking = '/ranking';
  static const String mural = '/mural';
  static const String materiais = '/materiais';
  static const String teams = '/teams';
  static const String atividades = '/atividades';
  static const String solicitacoes = '/solicitacoes';
  static const String agenda = '/agenda';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(codigoIndicacaoPrefill: args),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case eventos:
        return MaterialPageRoute(builder: (_) => const EventosScreen());
      case eventoDetalhe:
        final evento = settings.arguments as EventoModel;
        return MaterialPageRoute(
          builder: (_) => EventoDetalheScreen(evento: evento),
        );
      case checkin:
        final args = settings.arguments as CheckinScreenArgs?;
        return MaterialPageRoute(builder: (_) => CheckinScreen(args: args));
      case ranking:
        return MaterialPageRoute(builder: (_) => const RankingScreen());
      case mural:
        return MaterialPageRoute(builder: (_) => const MuralScreen());
      case materiais:
        return MaterialPageRoute(builder: (_) => const MateriaisScreen());
      case teams:
        return MaterialPageRoute(builder: (_) => const TeamsScreen());
      case atividades:
        return MaterialPageRoute(builder: (_) => const AtividadesScreen());
      case solicitacoes:
        return MaterialPageRoute(builder: (_) => const SolicitacoesScreen());
      case agenda:
        return MaterialPageRoute(builder: (_) => const AgendaScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
