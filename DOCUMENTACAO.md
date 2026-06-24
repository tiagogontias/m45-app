# M45 - Aplicativo de Mobilização Política

## 📋 Visão Geral

Aplicativo Flutter para mobilização política estadual, com foco em Windows (desktop). O app funciona com backend Supabase local e suporta modo offline-first com sincronização.

**Versão:** MVP Windows v1.0  
**Plataforma principal:** Windows (desktop)  
**Backend:** Supabase (local via Docker)  
**Frontend:** Flutter 3.44.2  
**Dart:** 3.12.2

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Windows)                      │
├─────────────────────────────────────────────────────────────┤
│  lib/                                                        │
│  ├── main.dart              → Entry point + DI setup         │
│  ├── core/                                                   │
│  │   ├── config.dart        → Configurações (Supabase URL)  │
│   │   ├── routes.dart       → Rotas de navegação             │
│   │   └── theme.dart        → Tema PSDB (azul/amarelo)      │
│  ├── models/                                                 │
│  │   ├── user_model.dart    → Modelo de usuário              │
│  │   ├── evento_model.dart  → Modelo de evento              │
│  │   ├── checkin_model.dart → Modelo de check-in            │
│  │   ├── mural_post_model.dart → Modelo de post no mural    │
│  │   ├── conexao_model.dart → Modelo de conexão             │
│  │   ├── interesse_model.dart → Modelo de interesses         │
│  │   └── material_model.dart → Modelo de material            │
│  ├── services/                                               │
│  │   ├── pocketbase_service.dart → Serviço Supabase (API)   │
│  │   ├── local_storage_service.dart → Cache offline (Hive)  │
│  │   ├── sync_service.dart   → Sincronização offline        │
│  │   └── notification_service.dart → Notificações (FCM)     │
│  ├── screens/                                                │
│  │   ├── login_screen.dart   → Login                        │
│  │   ├── register_screen.dart → Cadastro                    │
│  │   ├── home_screen.dart    → Tela inicial + navegação     │
│  │   ├── eventos_screen.dart → Lista/criação de eventos    │
│  │   ├── evento_detalhe_screen.dart → Detalhes do evento   │
│  │   ├── checkin_screen.dart → Check-in via token           │
│  │   ├── ranking_screen.dart → Top 100 usuários             │
│  │   ├── mural_screen.dart   → Posts do mural              │
│  │   ├── materiais_screen.dart → Materiais de campanha      │
│  │   └── profile_screen.dart → Perfil do usuário           │
│  └── shared/                                                 │
│      └── widgets/                                            │
│          ├── error_dialog.dart → Diálogo de erro            │
│          └── loading_button.dart → Botão com loading        │
├─────────────────────────────────────────────────────────────┤
│  Backend (Docker)                                            │
│  ├── Supabase Auth (GoTrue) → Autenticação                  │
│  ├── PostgREST               → API REST                     │
│  ├── Postgres 17             → Banco de dados               │
│  ├── Kong                    → API Gateway                  │
│  ├── Studio                  → Admin UI                     │
│  └── Storage                 → Arquivos (S3)                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Banco de Dados (Supabase)

### Tabelas

#### `auth.users` (gerenciada pelo Supabase Auth)
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Identificador único |
| email | text | Email do usuário |
| encrypted_password | text | Senha criptografada |
| email_confirmed_at | timestamptz | Data de confirmação |
| raw_user_meta_data | jsonb | Metadados (nome) |
| created_at | timestamptz | Data de criação |

#### `public.profiles`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid (FK → auth.users) | Identificador |
| nome text | Nome completo |
| email | text | Email |
| telefone | text | Telefone |
| cidade | text | Cidade |
| equipe_id | text | ID da equipe |
| cargo | text | militante/coordenador/admin |
| ativo | boolean | Usuário ativo |
| pontuacao_total | integer | Pontos acumulados |
| codigo_indicacao | text UNIQUE | Código M45-XXXXX |
| indicado_por | text | Código de quem indicou |
| areas_interesse | jsonb | Áreas de interesse |
| candidatos_apoio | jsonb | Candidatos apoiados |

#### `public.eventos`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| titulo | text | Título do evento |
| descricao | text | Descrição |
| data | date | Data do evento |
| horario | text | Horário |
| local | text | Local |
| geolocalizacao | jsonb | {lat, lng} |
| qr_code_token | text UNIQUE | Token para check-in |
| status | text | agendado/andamento/finalizado |
| criado_por | uuid (FK → users) | Criador |
| confirmados | integer | Nº confirmados |
| meta_participantes | integer | Meta de participantes |

#### `public.checkins`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| user_id | uuid (FK → users) | Usuário |
| evento_id | uuid (FK → eventos) | Evento |
| timestamp | timestamptz | Data/hora |
| tipo_checkin | text | entrada/confirmacao |
| geolocalizacao | jsonb | Localização |
| offline | boolean | Check-in offline? |
| token | text | Token usado |

#### `public.mural_posts`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| autor_id | uuid (FK → users) | Autor |
| titulo | text | Título |
| texto | text | Conteúdo |
| midia_url | text | URL da mídia |
| curtidas | jsonb | Array de user_id |
| data | timestamptz | Data do post |

#### `public.conexoes`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| user_id | uuid (FK → users) | Usuário |
| conexao_id | uuid (FK → users) | Conectado |
| tipo | text | indicacao/match_trabalho |
| evento_id | uuid (FK → eventos) | Evento relacionado |
| data | timestamptz | Data da conexão |

#### `public.interesses`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| user_id | uuid (FK → users) UNIQUE | Usuário |
| areas | jsonb | Áreas de interesse |
| candidatos_apoio | jsonb | Candidatos |
| ultima_troca_candidato | timestamptz | Última troca |

#### `public.materiais`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| titulo | text | Título |
| categoria | text | video/arte/pdf/treinamento/discurso |
| descricao | text | Descrição |
| arquivo_url | text | URL do arquivo |
| thumbnail | text | URL do thumbnail |

---

## 🔐 Autenticação

- **Login:** Email + senha via Supabase Auth
- **Cadastro:** Email + senha + nome + código de indicação (opcional)
- **Código M45:** Gerado automaticamente (M45-XXXXX)
- **Sessão:** JWT token gerenciado pelo Supabase

### Usuário Admin
- **Email:** tiagonrose2@gmail.com
- **Senha:** Zepilintra4656032
- **Código:** M45-00001
- **Cargo:** admin

---

## 🎮 Funcionalidades

### 1. Login e Cadastro
- Login com email/senha
- Cadastro com código de indicação
- Validação de código M45

### 2. Home
- BottomNavigationBar: Início, Eventos, Mural, Perfil
- Card do próximo evento (data >= hoje)
- Pontuação do usuário
- Grid de atalhos

### 3. Eventos
- Lista de eventos ordenados por data
- Cores por status: agendado=verde, andamento=amarelo, finalizado=cinza
- Botão "Criar Evento" (admin/coordenador)
- Filtro por status

### 4. Detalhe do Evento
- Informações completas
- Botão "Confirmar Presença" (+3 pontos)
- Se admin: lista de convidados pendentes
- Botão "Gerar QR Code"
- Botão "Convidar Amigo" (copia link)

### 5. Check-in
- Campo de texto para token (simula QR no Windows)
- Botão "Realizar Check-in" (+10 pontos)
- Se offline: salva no Hive com `offline: true`
- Sincronização automática quando detecta internet

### 6. Ranking
- Top 100 usuários por pontuação
- Destaque para posição do usuário logado
- Botão "Atualizar"

### 7. Mural
- Lista posts ordenados por data (desc)
- Botão "+" no AppBar (admin) para criar post
- Cada post: autor, título, texto, data

### 8. Materiais
- Lista de materiais de campanha
- Categorias: video, arte, pdf, treinamento, discurso
- Thumbnail e link para download

### 9. Perfil
- Exibir: nome, código M45, pontuação, equipe, interesses, candidatos
- Botão "Editar Perfil" (nome, telefone, interesses)
- Botão "Sair"

---

## 🔄 Sincronização Offline

1. Check-in sem internet → salvo em Hive com `offline: true`
2. SyncService detecta conectividade (wifi/mobile/ethernet)
3. Envia check-ins pendentes para Supabase
4. Remove do cache após sucesso
5. Atualiza pontuação local

---

## 📊 Sistema de Pontuação

| Ação | Pontos |
|------|--------|
| Realizar check-in | +10 |
| Confirmar presença | +3 |
| Indicação que vira presença | +30 |

---

## 🛠️ Tecnologias

| Tecnologia | Versão | Uso |
|------------|--------|-----|
| Flutter | 3.44.2 | Framework UI |
| Dart | 3.12.2 | Linguagem |
| Supabase | Local (Docker) | Backend/Auth |
| Hive | 2.2.0 | Cache offline |
| GetIt | 7.6.0 | Injeção de dependência |
| Connectivity Plus | 5.0.2 | Detecção de rede |
| HTTP | 1.1.0 | Requisições REST |
| Path Provider | 2.1.0 | Diretórios locais |

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.44.2+
- Docker Desktop (para Supabase)
- Node.js (para Supabase CLI)

### 1. Iniciar Supabase
```powershell
cd C:\m45\supabase
supabase start
```
Aguarde até aparecer "Started supabase local development setup."

### 2. Instalar dependências
```powershell
cd C:\m45\flutter_app
flutter pub get
```

### 3. Rodar o app
```powershell
flutter run -d windows
```

### 4. Gerar executável
```powershell
flutter build windows --release
```
Executável em: `build/windows/runner/Release/`

---

## 📁 Estrutura de Arquivos

```
C:\m45\flutter_app\
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config.dart
│   │   ├── routes.dart
│   │   └── theme.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── evento_model.dart
│   │   ├── checkin_model.dart
│   │   ├── mural_post_model.dart
│   │   ├── conexao_model.dart
│   │   ├── interesse_model.dart
│   │   └── material_model.dart
│   ├── services/
│   │   ├── pocketbase_service.dart (Supabase API)
│   │   ├── local_storage_service.dart (Hive)
│   │   ├── sync_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── eventos_screen.dart
│   │   ├── evento_detalhe_screen.dart
│   │   ├── checkin_screen.dart
│   │   ├── ranking_screen.dart
│   │   ├── mural_screen.dart
│   │   ├── materiais_screen.dart
│   │   └── profile_screen.dart
│   └── shared/
│       └── widgets/
│           ├── error_dialog.dart
│           └── loading_button.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── windows/ (gerado pelo flutter create)
```

---

## ⏭️ Próximos Passos (Roadmap)

### Prompt 3 - Indicações e Match
- [ ] Tela de Indicações (código, ranking de indicadores)
- [ ] Sistema de match por interesses
- [ ] Notificação quando indicado confirmar presença

### Prompt 4 - Notificações Push
- [ ] Integração FCM (Firebase Cloud Messaging)
- [ ] Notificações de eventos próximos
- [ ] Notificações de confirmação de indicação

### Prompt 5 - Perfil Avançado
- [ ] Filtros para coordenação (por equipe, área, cargo)
- [ ] Gestão de candidatos apoiados
- [ ] Histórico de atividades

### Prompt 6 - Android e Deploy
- [ ] Resolver Gradle/Java/NDK para Android
- [ ] Build APK
- [ ] Integração NGINX/IPFS para materiais
- [ ] Deploy com Cloudflare Tunnel

### Melhorias Técnicas
- [ ] Testes unitários e de widget
- [ ] RLS (Row Level Security) no Supabase
- [ ] Error handling global
- [ ] Loading states em todas as telas
- [ ] Validação de formulários
- [ ] Internacionalização (pt-BR)

---

## 📝 Notas

- O Supabase usa senha padrão: `supabase123` (configurável no docker-compose)
- O código M45 é gerado automaticamente no cadastro
- Check-ins offline são sincronizados automaticamente
- O tema segue as cores do PSDB: azul (#003399) e amarelo (#FFCC00)
- O app foi testado e validado no Windows 10

---

**Desenvolvido por:** Tiago Gontias  
**Data:** Junho 2026  
**Versão:** MVP Windows v1.0
