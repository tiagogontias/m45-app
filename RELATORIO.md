# 📊 Relatório M45 — Estado Atual do Projeto

**Data:** 01/07/2026  
**Versão:** 1.1.0 (Núcleo Operacional)  
**Desenvolvedor:** Tiago Gontias  
**Sessão de retomada:** continuação após reorganização de arquitetura

---

## 1. Visão Geral

M45 é um aplicativo Flutter para coordenação e mobilização política estadual. O foco **deixou de ser rede social** e passou a ser **plataforma de gestão de campanha** (equipes, atividades, agenda, mural oficial, solicitações). O backend é Supabase Cloud com PostgREST + Auth.

| Componente | Status | Detalhes |
|---|---|---|
| Flutter App | ✅ Funcional | Compila e roda no Windows; build de release gera `.exe` |
| Supabase Cloud | ✅ Conectado | URL `rrnoxicqxuubirucybph`, anon key configurada |
| Auth | ✅ Login/Cadastro | Via Supabase Auth + JWT |
| Núcleo de Mobilização | ✅ Implementado | Equipes, atividades, agenda, check-in/out, mural, solicitações |
| RLS (Row Level Security) | ❌ Pendente | Tabelas abertas; **bloqueador de produção** |
| Middleware de permissão | ❌ Pendente | Cargo está no profile mas UI não filtra por ele |
| Dashboard UI | ❌ Pendente | Service `getDashboardIndicadores()` existe; tela não foi criada |
| Gestão de Solicitações UI | ❌ Pendente | Service existe; tela de aprovação por coordenador não foi criada |
| Build Android | ❌ Pendente | Bloqueado por Gradle/Java/NDK |
| Edge Functions | ⚠️ Criada local | `C:\m45\supabase\supabase\functions\m45-api\index.ts` — não deployada |
| Usuário admin | ❌ Pendente | Rate limit do Supabase impediu criação |

---

## 2. Estado do Repositório

- **Remote:** `github.com/tiagogontias/m45-app` (branch `main`)
- **Últimos commits:**
  - `2daebf1` — feat: Nucleo operacional completo - Solicitacoes, Dashboard, Agenda, Check-out, Participacao
  - `21611c9` — refactor: Reorganização M45 - Plataforma de Coordenação e Mobilização
  - `3c3fc06` — feat: Prompt 3 - Sistema de Indicações, Ranking de Indicadores e Match por Interesses
  - `ab21d53` — feat: MVP Windows M45 v1.0 - Supabase Cloud migration complete
- **Working tree:** limpo (apenas `RELATORIO.md` e `.hermes/plans/check_cloud.py` untracked — ambos a serem comitados nesta sessão)

---

## 3. Estrutura Atual do Código (verificada)

### Telas (14)
```
lib/screens/
├── agenda_screen.dart          (115 linhas) — unifica eventos + atividades
├── atividades_screen.dart      (111 linhas) — bandeiragem, panfletagem, etc.
├── checkin_screen.dart         (171 linhas) — token + offline
├── evento_detalhe_screen.dart  (289 linhas) — confirmar + check-out
├── eventos_screen.dart         (222 linhas) — lista + criar (admin)
├── home_screen.dart            (307 linhas) — atalhos: Eventos, Check-in, Materiais, Ranking
├── login_screen.dart           (145 linhas)
├── materiais_screen.dart       (130 linhas)
├── mural_screen.dart           (161 linhas) — só admin publica
├── profile_screen.dart         (259 linhas) — equipe + cargo
├── ranking_screen.dart         (90 linhas) — top 100, mantido pessoal
├── register_screen.dart        (194 linhas)
├── solicitacoes_screen.dart    (181 linhas) — criar/listar próprias
└── teams_screen.dart           (141 linhas) — gestão de equipes
```

### Models (9 — incluindo 4 novos do núcleo)
```
lib/models/
├── atividade_model.dart     [NOVO]
├── checkin_model.dart
├── convite_model.dart       [NOVO]
├── evento_model.dart
├── material_model.dart
├── mural_post_model.dart
├── solicitacao_model.dart   [NOVO]
├── team_model.dart          [NOVO]
└── user_model.dart
```

### Services (4)
```
lib/services/
├── pocketbase_service.dart   (913 linhas, 41 métodos — incluindo 7 legados não usados)
├── local_storage_service.dart
├── sync_service.dart
└── notification_service.dart  (placeholder FCM)
```

---

## 4. Tabelas Supabase (verificadas via service)

| Tabela | Cols principais | UI consome? |
|---|---|---|
| `profiles` | cargo, equipe_id, coordenador_id, estado | ✅ |
| `eventos` | data, local, qr_code_token, status, confirmados | ✅ |
| `checkins` | tipo_checkin (entrada/saida/confirmacao), offline | ✅ |
| `mural_posts` | titulo, texto, autor_id, midia_url | ✅ |
| `materiais` | categoria, arquivo_url, thumbnail | ✅ |
| `teams` | nome, municipio, coordenador_id, ativa | ✅ |
| `convites` | email, team_id, token, status | ✅ (criação) |
| `atividades` | tipo, data, hora_inicio/fim, equipe_id | ✅ |
| `participacoes_atividades` | atividade_id, user_id, status | ✅ |
| `solicitacoes` | tipo, status, resposta, solicitante_id | ✅ (parcial) |
| `conexoes` | — | ❌ Legado |
| `interesses` | — | ❌ Legado |

---

## 5. O Que Mudou Nesta Sessão

### 1. Reorganização de arquitetura (`21611c9`)
Removido tudo que era rede social, mantido e expandido tudo que é coordenação.

### 2. Núcleo operacional (`2daebf1`)
Adicionado suporte a solicitações, agenda unificada, check-out, participação em atividades. Service backend completo.

### 3. Esta sessão
- Documentação (`DOCUMENTACAO.md`) reescrita para refletir o estado real do código.
- Mapeados buracos entre service e UI (Dashboard, Gestão de Solicitações).
- Identificado código morto em `pocketbase_service.dart`.

---

## 6. Buracos Conhecidos (service existe, UI não)

| Funcionalidade | Service | UI |
|---|---|---|
| Indicadores agregados (coord.) | `getDashboardIndicadores()` | ❌ Ausente |
| Aprovar/recusar solicitações | `getSolicitacoesGestao()` + `updateSolicitacaoStatus()` | ❌ Ausente |
| Convite por link/token | `enviarConvite()` | ❌ Tela de aceitação ausente |
| Convocação de equipe | — | ❌ Não implementado |

---

## 7. Bloqueadores para Deploy em Produção

1. **RLS não configurado** — qualquer usuário autenticado lê/edita qualquer tabela
2. **Middleware de cargo ausente** — UI não filtra por `super_admin / coordenador / militante`
3. **Admin master não criado** — bloqueado por rate limit do Supabase (precisa tentar de novo ou usar `supabase admin` via service key)
4. **Edge Function não deployada** — existe local em `C:\m45\supabase\supabase\functions\m45-api\` mas não foi publicada

---

## 8. Decisões Pendentes

| Tema | Decisão |
|---|---|
| RLS策略 | Ativar políticas por cargo? (recomendado) ou coluna `is_admin` no JWT? |
| Permissões | Middleware em `routes.dart` (centralizado) ou `if (user.isAdmin)` espalhado? |
| Vídeos no mural | `youtube_player_flutter` (confirmado na decisão anterior) — implementar |
| Materiais pesados | Cloudflare R2 (decidido) — ainda não provisionado |
| Indicadores | Tela única consolidada ou widgets no Home? |

---

## 9. Como Testar Localmente

```powershell
# 1. App
cd C:\m45\flutter_app
flutter pub get
flutter run -d windows

# 2. Build
flutter build windows --release
# Executável: build\windows\runner\Release\m45_app.exe

# 3. Supabase (se voltar a usar local)
cd C:\m45\supabase
supabase start

# 4. Edge Function (quando for deployar)
supabase functions deploy m45-api
```

---

## 10. Comandos Úteis do Ambiente

```bash
# Hermes
hermes config path          # caminho do config.yaml
hermes session list         # listar sessões
hermes session export <id>  # exportar sessão antes de fechar
```

```powershell
# Windows
where flutter               # localizar SDK
flutter doctor              # diagnóstico
flutter devices             # listar devices
```

---

**Gerado pelo Hermes Agent**  
**Última atualização:** 01/07/2026 — pós-reorganização
