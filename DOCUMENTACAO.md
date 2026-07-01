# M45 — Plataforma de Coordenação e Mobilização Política

## 📋 Visão Geral

Aplicativo Flutter **offline-first** para coordenação, mobilização e gestão de equipes de campanha política. Foco em Windows desktop (rodando 100% funcional). Backend **Supabase Cloud** (PostgREST + Auth).

**Versão:** 1.1.0 (Núcleo Operacional)  
**Plataforma principal:** Windows desktop  
**Backend:** Supabase Cloud (`rrnoxicqxuubirucybph`)  
**Frontend:** Flutter 3.44.2 / Dart 3.12.2  
**Repositório:** `github.com/tiagogontias/m45-app`

---

## 🎯 Mudança de Arquitetura (jun/2026)

O M45 deixou de ser **rede social política** e virou **plataforma de coordenação e mobilização**. Funcionalidades sociais foram **removidas** e substituídas por núcleo operacional de campanha.

### Removido (não existe mais na UI)
| Funcionalidade | Removido em | Status |
|---|---|---|
| Chat entre militantes | 21611c9 | ❌ Rota/service deletados |
| Match por interesses | 21611c9 | ❌ Tela e service removidos |
| Ranking público de indicadores | 21611c9 | ❌ Tela removida; service orfão no `pocketbase_service.dart` |
| Tela de Indicações (social) | 21611c9 | ❌ Substituída por convites de equipe |
| Feed social / timeline | 21611c9 | ❌ Nunca existiu nesta versão |
| Pesquisas | n/a | ❌ Fora de escopo |

> **Atenção:** o service `pocketbase_service.dart` ainda contém `criarConexao()`, `salvarInteresses()`, `getMatches()`, `criarMatch()` (linhas ~383-579) como **código morto**. Recomendado remover na próxima limpeza.

---

## 🏗️ Arquitetura

```
┌──────────────────────────────────────────────────────┐
│              Flutter App (Windows)                     │
├──────────────────────────────────────────────────────┤
│  lib/                                                  │
│  ├── main.dart              → Entry + onGenerateRoute│
│  ├── core/                                              │
│  │   ├── config.dart        → Supabase URL/keys (env)│
│  │   ├── routes.dart        → 14 rotas                │
│  │   └── theme.dart         → Tema PSDB (azul/amarelo)│
│  ├── models/                                           │
│  │   ├── user_model.dart                                 │
│  │   ├── evento_model.dart                              │
│  │   ├── checkin_model.dart                             │
│  │   ├── mural_post_model.dart                          │
│  │   ├── material_model.dart                            │
│  │   ├── team_model.dart          ← NOVO                │
│  │   ├── convite_model.dart        ← NOVO                │
│  │   ├── atividade_model.dart      ← NOVO                │
│  │   └── solicitacao_model.dart    ← NOVO                │
│  ├── services/                                         │
│  │   ├── pocketbase_service.dart  → REST + Auth        │
│  │   ├── local_storage_service.dart → Cache Hive       │
│  │   ├── sync_service.dart         → Sync offline      │
│  │   └── notification_service.dart → FCM (placeholder) │
│  ├── screens/                  → 14 telas (ver abaixo) │
│  └── shared/widgets/                                    │
│      ├── error_dialog.dart                              │
│      └── loading_button.dart                           │
├──────────────────────────────────────────────────────┤
│  Backend (Supabase Cloud)                              │
│  ├── Auth (GoTrue)         → JWT                       │
│  ├── PostgREST             → API REST                  │
│  ├── Postgres              → Banco                     │
│  ├── Storage               → Avatares (futuro)         │
│  └── Edge Functions        → (criada, não deployada)   │
└──────────────────────────────────────────────────────┘
```

---

## 🗄️ Banco de Dados (Supabase Cloud)

### URL e Credenciais
```
URL:    https://rrnoxicqxuubirucybph.supabase.co
Anon:   sb_publishable_TR3I0nVwDhlTz8SM-H0YSg_C_nSs5m_
Secret: [via env var SUPABASE_SECRET_KEY, nunca no código]
```

### Tabelas em uso

#### `public.profiles` (campos adicionados na reorganização)
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (FK → auth.users) PK | Identificador |
| nome | text | Nome completo |
| email | text | Email |
| telefone | text | Telefone |
| cidade | text | Cidade |
| estado | text | **NOVO** — Estado (UF) |
| equipe_id | text | **NOVO** — FK para `teams` |
| coordenador_id | uuid | **NOVO** — FK para users (coordenador direto) |
| cargo | text | super_admin / coordenador_geral / coordenador_municipal / militante |
| ativo | boolean | Usuário ativo |
| pontuacao_total | integer | Pontos |
| codigo_indicacao | text UNIQUE | M45-XXXXX |
| indicado_por | text | Código de quem indicou |
| areas_interesse | jsonb | Áreas de interesse |
| candidatos_apoio | jsonb | Candidatos apoiados |

#### `public.teams` (NOVA)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| nome | text |
| descricao | text |
| coordenador_id | uuid (FK → users) |
| municipio | text |
| ativa | boolean |
| created_at | timestamptz |

#### `public.convites` (NOVA)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| email | text |
| team_id | uuid (FK → teams) |
| token | text |
| status | pendente / aceito / recusado / expirado |
| criado_por | uuid (FK → users) |

#### `public.atividades` (NOVA)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| titulo | text |
| descricao | text |
| local | text |
| data | date |
| hora_inicio | time |
| hora_fim | time |
| tipo | bandeiraco / panfletagem / reuniao / mobilizacao / adesivagem |
| equipe_id | uuid (FK → teams) |
| coordenador_id | uuid (FK → users) |
| status | agendado / em_andamento / concluido / cancelado |

#### `public.participacoes_atividades` (NOVA — núcleo operacional)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| atividade_id | uuid (FK → atividades) |
| user_id | uuid (FK → users) |
| status | confirmado / recusado / pendente |
| data_resposta | timestamptz |

#### `public.solicitacoes` (NOVA — núcleo operacional)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| solicitante_id | uuid (FK → users) |
| tipo | combustivel / material_grafico / adesivos / outros |
| descricao | text |
| status | aberto / aprovado / recusado / concluido |
| resposta | text |
| data | timestamptz |

#### `public.eventos` (mantida)
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid PK | |
| titulo | text | |
| descricao | text | |
| data | date | |
| horario | text | |
| local | text | |
| geolocalizacao | jsonb | {lat, lng} |
| qr_code_token | text UNIQUE | Token para check-in |
| status | text | agendado / andamento / finalizado |
| criado_por | uuid | |
| confirmados | integer | |
| meta_participantes | integer | |

#### `public.checkins` (mantida + suporte a saída)
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid PK | |
| user_id | uuid | |
| evento_id | uuid | |
| timestamp | timestamptz | |
| tipo_checkin | text | **entrada** / **saida** / **confirmacao** |
| geolocalizacao | jsonb | |
| offline | boolean | |
| token | text | |

#### `public.mural_posts` (mantida, agora só admin publica)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| autor_id | uuid |
| titulo | text |
| texto | text |
| midia_url | text |
| curtidas | jsonb |
| data | timestamptz |

#### `public.materiais` (mantida)
| Campo | Tipo |
|---|---|
| id | uuid PK |
| titulo | text |
| categoria | video / arte / pdf / treinamento / discurso |
| descricao | text |
| arquivo_url | text |
| thumbnail | text |

### Tabelas legadas (sem UI, sem uso novo)
- `conexoes` — existia para match/indicação social. Não é mais consultada.
- `interesses` — existia para match por área. Não é mais consultada.
- Podem ser removidas em migração futura.

---

## 🧭 Hierarquia de Cargos

```
super_admin         (Tiago — controle total)
   ↓
coordenador_geral   (visão multi-município)
   ↓
coordenador_municipal (visão da equipe)
   ↓
militante           (acesso individual)
```

**Status atual:** o campo `cargo` é persistido, mas o **middleware de permissão nas rotas ainda não está implementado**. A UI usa lógica de `isAdmin` hardcoded em alguns pontos (ex: mural, criar evento). **Próximo passo crítico** antes de deploy.

### Permissões pretendidas
| Cargo | Vê | Cria |
|---|---|---|
| Militante | Próprio perfil, agenda, mural | Check-in, solicitações |
| Coord. Municipal | Equipe + agenda | Atividades, convocações |
| Coord. Geral | Todos os municípios | — |
| Super Admin | Tudo | Posts mural, eventos, exportar |

---

## 📱 Telas Implementadas (14)

| Tela | Rota | Status | Função |
|---|---|---|---|
| `LoginScreen` | `/login` | ✅ | Email + senha |
| `RegisterScreen` | `/register` | ✅ | Com código indicação |
| `HomeScreen` | `/home` | ✅ | Próximo evento + atalhos (Eventos/Check-in/Materiais/Ranking) |
| `EventosScreen` | `/eventos` | ✅ | Lista + criar (admin) |
| `EventoDetalheScreen` | `/evento-detalhe` | ✅ | Confirmar + Check-out |
| `CheckinScreen` | `/checkin` | ✅ | Token + offline |
| `RankingScreen` | `/ranking` | ✅ | Top 100 — legado, manter pessoal |
| `MuralScreen` | `/mural` | ✅ | Só admin publica |
| `MateriaisScreen` | `/materiais` | ✅ | Lista |
| `ProfileScreen` | `/profile` | ✅ | Exibe equipe + cargo + editar |
| `TeamsScreen` | `/teams` | ✅ | Gestão de equipes |
| `AtividadesScreen` | `/atividades` | ✅ | Bandeiragem, panfletagem, etc. |
| `SolicitacoesScreen` | `/solicitacoes` | ✅ | Criar/listar solicitações |
| `AgendaScreen` | `/agenda` | ✅ | Unifica eventos + atividades |

**Pendências de UI:**
- `DashboardCoordenacaoScreen` (mencionada no commit `2daebf1`) — **não foi criada** apesar do service `getDashboardIndicadores()` existir.
- `SolicitacoesGestaoScreen` (aprovação por coordenadores) — **não foi criada** apesar de `getSolicitacoesGestao()` e `updateSolicitacaoStatus()` existirem.

> Esses são buracos claros entre o service e a UI. Para deploy real, precisam ser fechados.

---

## ⚙️ PocketBaseService — Mapa de Endpoints

| Categoria | Métodos |
|---|---|
| **Auth** | `login`, `register`, `logout`, `getCurrentUser`, `getUserById`, `getUserByCode` |
| **Eventos** | `getEventos`, `getEvento`, `createEvento`, `confirmarPresenca` |
| **Check-in/out** | `realizarCheckin`, `realizarCheckOut`, `gerarQrCodeToken`, `getConvidadosPendentes` |
| **Mural** | `getMuralPosts`, `createMuralPost` |
| **Ranking** | `getRanking` |
| **Materiais** | `getMateriais` |
| **Equipes** | `getTeams`, `createTeam` |
| **Convites** | `enviarConvite` |
| **Atividades** | `getAtividades`, `createAtividade`, `confirmarParticipacao`, `getParticipacoes` |
| **Solicitações** | `createSolicitacao`, `getMinhasSolicitacoes`, `getSolicitacoesGestao`, `updateSolicitacaoStatus` |
| **Dashboard** | `getDashboardIndicadores` |
| **Agenda** | `getAgenda` (unifica eventos + atividades) |
| **Legado (morto)** | `criarConexao`, `salvarInteresses`, `getMatches`, `criarMatch`, `getIndicados`, `getIndicacoesConvertidas`, `getRankingIndicadores` |

---

## 📊 Sistema de Pontuação

| Ação | Pontos |
|---|---|
| Realizar check-in (entrada) | +10 |
| Confirmar presença em evento | +3 |
| Indicação convertida (indicado faz 1º check-in) | +30 |

**Status:** regras implementadas no service. **Ranking público removido** — apenas o usuário vê sua própria pontuação em `ProfileScreen`. Coordenadores veem indicadores agregados via `getDashboardIndicadores()`.

---

## 🔄 Sincronização Offline

1. Check-in sem internet → salvo em Hive com `offline: true`
2. `SyncService` detecta conectividade (via `connectivity_plus`)
3. Envia check-ins pendentes para Supabase
4. Remove do cache após sucesso
5. Atualiza pontuação local

---

## 🛠️ Tecnologias

| Tech | Versão | Uso |
|---|---|---|
| Flutter | 3.44.2 | Framework UI |
| Dart | 3.12.2 | Linguagem |
| Supabase | Cloud | Backend/Auth/DB |
| Hive | 2.2.0 | Cache offline |
| GetIt | 7.6.0 | Injeção de dependência |
| Provider | 6.1.0 | State management |
| Connectivity Plus | 5.0.2 | Detecção de rede |
| HTTP | 1.1.0 | Requisições REST |
| PocketBase SDK | 0.18.0 | (legado, mantido no pubspec) |

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.44.2+
- Conta Supabase Cloud (projeto `rrnoxicqxuubirucybph`)

### 1. Instalar dependências
```powershell
cd C:\m45\flutter_app
flutter pub get
```

### 2. Rodar o app
```powershell
flutter run -d windows
```

### 3. Gerar executável
```powershell
flutter build windows --release
```
**Saída:** `build/windows/runner/Release/m45_app.exe`

---

## 📁 Estrutura Atual

```
C:\m45\flutter_app\
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config.dart
│   │   ├── routes.dart          (14 rotas)
│   │   └── theme.dart
│   ├── models/                  (9 models)
│   │   ├── user_model.dart
│   │   ├── evento_model.dart
│   │   ├── checkin_model.dart
│   │   ├── mural_post_model.dart
│   │   ├── material_model.dart
│   │   ├── team_model.dart
│   │   ├── convite_model.dart
│   │   ├── atividade_model.dart
│   │   └── solicitacao_model.dart
│   ├── services/                (4 services)
│   │   ├── pocketbase_service.dart  (913 linhas, 41 métodos)
│   │   ├── local_storage_service.dart
│   │   ├── sync_service.dart
│   │   └── notification_service.dart
│   ├── screens/                 (14 telas)
│   └── shared/widgets/
│       ├── error_dialog.dart
│       └── loading_button.dart
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── windows/                     (gerado pelo flutter create)
```

---

## ⏭️ Próximos Passos (Roadmap)

### Imediato (bloqueadores)
- [ ] **Criar `DashboardCoordenacaoScreen`** — usar `getDashboardIndicadores()` (já implementado)
- [ ] **Criar `SolicitacoesGestaoScreen`** — usar `getSolicitacoesGestao()` + `updateSolicitacaoStatus()`
- [ ] **Implementar middleware de permissão por cargo** nas rotas
- [ ] **Limpar código morto** em `pocketbase_service.dart` (métodos de match/conexão)
- [ ] **Configurar RLS** (Row Level Security) no Supabase para cada tabela
- [ ] **Criar usuário admin** e seed de dados (rate limit do Supabase foi o bloqueio anterior)

### Curto prazo
- [ ] Tela de aceitação de convite (link/token)
- [ ] Tela de convocação de equipe (coordenador → militante)
- [ ] Filtros de coordenação em `AgendaScreen` (por equipe, município)
- [ ] Notificações in-app (substituir FCM placeholder)

### Médio prazo
- [ ] Build Android (resolver Gradle/Java/NDK)
- [ ] Integração `youtube_player_flutter` para vídeos do mural
- [ ] Cloudflare Tunnel para expor Supabase local
- [ ] Relatórios para super_admin (exportar CSV)

### Longo prazo
- [ ] Testes unitários e de widget (cobertura mínima 60%)
- [ ] Internacionalização (pt-BR)
- [ ] PWA ou versão web do app

---

## 🔐 Admin Master

- **Email:** tiagonrose2@gmail.com
- **Senha:** Zepilintra4656032
- **Cargo esperado:** super_admin
- **Status:** precisa ser criado no Supabase Auth (rate limit impediu antes)

---

## 📝 Histórico de Commits Relevantes

| SHA | Mensagem |
|---|---|
| `2daebf1` | feat: Nucleo operacional completo - Solicitacoes, Dashboard, Agenda, Check-out, Participacao |
| `21611c9` | refactor: Reorganização M45 - Plataforma de Coordenação e Mobilização |
| `3c3fc06` | feat: Prompt 3 - Sistema de Indicações, Ranking de Indicadores e Match por Interesses |
| `ab21d53` | feat: MVP Windows M45 v1.0 - Supabase Cloud migration complete |

---

## 📌 Notas Operacionais

- **Secret key Supabase:** nunca vai para o código. Lida via `String.fromEnvironment('SUPABASE_SECRET_KEY')`.
- **cmd.exe suprime output:** usar `bash -c "..."` ou Python via `execute_code` para comandos que precisam de retorno.
- **Build Windows:** sempre testar com `flutter run -d windows` antes de `flutter build windows --release`.
- **Tema:** PSDB — azul `#003399` + amarelo `#FFCC00`.
- **Sessão Hermes:** provider `ollama-cloud` exige `OLLAMA_API_KEY`; para trocar, editar `config.yaml` diretamente (não usar `hermes model`).

---

**Desenvolvido por:** Tiago Gontias  
**Última atualização:** 01/07/2026  
**Versão:** 1.1.0 (Núcleo Operacional)
