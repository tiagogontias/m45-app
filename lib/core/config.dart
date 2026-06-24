class AppConfig {
  AppConfig._();

  // Supabase Cloud - usar variáveis de ambiente em produção
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://rrnoxicqxuubirucybph.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_TR3I0nVwDhlTz8SM-H0YSg_C_nSs5m_');
  // NUNCA colocar secret key no código-fonte. Usar variável de ambiente ou servidor.
  static const String supabaseServiceKey = String.fromEnvironment('SUPABASE_SECRET_KEY', defaultValue: '');

  // Legacy (mantido para referência)
  static const String pocketBaseUrl = 'http://localhost:8090';
  static const String nginxUrl = 'http://localhost/midia/';

  static const String appName = 'M45';
  static const String codigoPrefixo = 'M45';
}
