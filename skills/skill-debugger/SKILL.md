---
name: skill-debugger
description: Diagnoses Claude Code skill, hook, and MCP failures using an ordered diagnostic playbook. The skill activates when the user reports a Claude Code ecosystem problem — skill not triggering, skill stopped working after many turns, hook not blocking, MCP server with zero tools, "executed but did nothing", behavior that differs between repos, or any "why isn't my skill firing" question. Common PT-BR triggers include "minha skill não dispara", "não está chamando a skill", "a skill parou de funcionar", "hook não está bloqueando", "mcp não conecta", "executou mas não fez nada", "por que a skill X não rodou", "debug skill", "depurar skill". Does NOT activate for application code bugs in the user's project — only Claude Code infrastructure issues.
---

# Claude Code Skill Debugger

Diagnostica falhas em skills, hooks e servidores MCP do Claude Code seguindo
um playbook ordenado do exterior para o interior. Cada fase elimina uma classe
inteira de causas antes da próxima.

## Critical Rules

- NEVER skip diagnostic phases. The order A → I exists because each phase
  eliminates a class of root causes. Jumping straight to logs without checking
  `/skills` first wastes inference on hypotheses that `/skills` would have
  ruled out in one command.
- NEVER recommend `--dangerously-skip-permissions` as a fix. It is a diagnostic
  tool only — used to confirm a permission-class problem, then immediately
  reverted. If the user is already running with this flag, flag it as risk.
- NEVER assume tool execution succeeded based on Claude's natural-language
  report. If correctness matters, verify by reading the JSONL transcript and
  counting actual `tool_use` blocks.
- NEVER write to stdout in stdio MCP server context. Stderr only. Stdout
  corrupts JSON-RPC.
- NEVER recommend storing `permissions`, `hooks`, or `env` in `~/.claude.json`.
  That file is application state. Configuration goes in `~/.claude/settings.json`.
- NEVER recommend switching models mid-session during debugging. Each model has
  its own KV cache prefix; switching invalidates it and re-warm costs more than
  any savings.
- MUST verify Claude Code version with `claude --version` before applying
  version-gated advice (see "Version-gated features" in `reference/edge-cases.md`).

## Mandatory Diagnostic Order

Execute these phases in order. Do NOT proceed to phase N+1 until phase N has
been completed and produced a definite signal.

1. **Plataforma e estado global** (Phase A) — descartar falha de infraestrutura
2. **Discovery da skill** (Phase B) — a skill foi descoberta?
3. **Visibilidade no contexto** (Phase C) — o modelo está vendo a description?
4. **Roteamento** (Phase D) — manual funciona? auto não?
5. **Permissões e sandbox** (Phase E) — bloqueio de tool?
6. **MCP** (Phase F) — só se a skill depende de MCP server
7. **Hooks** (Phase G) — só se hooks estão envolvidos
8. **Telemetria** (Phase H) — leitura de logs e transcripts
9. **Replay isolado** (Phase I) — reproduzir script fora do agente

Não combine fases. Não pule para H sem ter passado por B–E. Se uma fase
retornar sinal claro de causa raiz, pare ali e proponha o fix — não continue
para fases seguintes "por completude".

## Phase A — Plataforma e estado global

Antes de qualquer hipótese local, descarte falha de plataforma:

```text
/doctor      # valida settings.json e schema
/status      # mostra fontes ativas de settings, incluindo managed
```

Cheque também a Anthropic Status Page para incidentes regionais (especialmente
HTTP 429). Se `/doctor` reporta erro de schema, **pare aqui** e corrija o JSON
antes de continuar — qualquer outro diagnóstico ficará contaminado.

## Phase B — Discovery da skill

```text
/skills      # lista skills carregadas, agrupadas por origem
```

Se a skill **não aparece**, consulte a tabela em `reference/symptoms.md` seção
"Discovery failures". As 5 causas mais comuns:

1. Arquivo solto `<nome>.md` em vez de pasta `<nome>/SKILL.md`
2. Frontmatter YAML inválido — valide com `head -10 SKILL.md` (deve abrir e fechar com `---`)
3. Diretório criado **depois** do início da sessão — relance `claude`
4. Nome com maiúsculas/espaços/acentos — `name:` exige `[a-z0-9-]{1,64}`
5. `--add-dir` esperando carregar `agents/` ou `commands/` (só `.claude/skills/` é descoberto)

## Phase C — Visibilidade no contexto

```text
/context     # mostra o que ocupa o contexto
```

Se a skill está em `/skills` mas **não** em `/context`, o orçamento de chars
truncou. Fixes:

```bash
export SLASH_COMMAND_TOOL_CHAR_BUDGET=20000   # antes de iniciar claude
```

Ou encurte `description` + `when_to_use` para caber no cap de 1.536 chars por
entrada.

## Phase D — Roteamento (decisão de invocação)

Force invocação manual:

```text
/<nome-da-skill> arg1 arg2
```

- Manual funciona, auto nunca dispara → problema é a `description`. Front-load
  palavras-chave do vocabulário do usuário. Se é skill PT-BR, adicione gatilhos
  em ambos idiomas.
- Manual também não funciona → volte para Phase B (discovery falhou).
- Aparece como "user-only" em `/skills` → `disable-model-invocation: true` está
  setado. Confirme se foi intencional.

## Phase E — Permissões e sandbox

```text
/permissions     # mostra allow/ask/deny resolvidos
```

Se suspeita de bloqueio de permissão **puramente para diagnóstico** (nunca em
produção, nunca como fix permanente):

```bash
claude --dangerously-skip-permissions ...
```

Se com isso funciona, ajuste `~/.claude/settings.json` ou `.claude/settings.json`.

Para gotchas de sandbox (WSL1 sem suporte, write em `.claude/skills/` bloqueado
em v2.1.38+, ferramentas com Unix sockets incompatíveis), consulte
`reference/symptoms.md` seção "Sandbox failures".

## Phase F — MCP (só se a skill depende de MCP)

```text
/mcp     # status de cada servidor: connected/failed + tools
```

Se "0 tools" connected → tente Reconnect. Se persistir, vá direto para
`reference/mcp-debug.md` que tem o playbook completo: stderr capture por
transporte, gotchas Windows+npx, propagação de env vars, MCP Inspector,
handshake errors.

## Phase G — Hooks (só se hooks estão envolvidos)

```text
/hooks                # lista hooks ativos por evento
claude --debug hooks  # mostra cada decisão de matcher live
```

Se hook não dispara, 90% das vezes é uma destas três causas:

1. `matcher` é JSON array em vez de string. Use `"Edit|Write"` (string com pipe).
2. Tool name lowercase. É case-sensitive: `Bash` ✓, `bash` ✗.
3. Hook em arquivo `.claude/hooks.json` standalone. Não existe — vai sob chave
   `"hooks"` em `settings.json`.

Para semântica completa de exit codes por evento, loop infinito em Stop hook,
e patterns de defesa via PostToolUse, consulte `reference/hooks-debug.md`.

## Phase H — Telemetria de baixo nível

Quando as fases anteriores não isolaram a causa, hora de logs:

```bash
claude --debug "api,mcp,hooks" --debug-file /tmp/cc.log
tail -F ~/.claude/debug/*.txt
```

Bundled skill (v2.1.30+):

```text
/debug por que a skill X não foi acionada?
```

Lê `~/.claude/debug/<session-id>.txt` da própria sessão e responde em
linguagem natural.

Inspeção de transcript JSONL:

```bash
jq -c 'select(.type=="tool_use" or .type=="tool_result")' \
   ~/.claude/projects/<cwd-encoded>/<sid>.jsonl
```

Bare mode para isolar se a falha vem de outra config:

```bash
claude --bare -p "..."   # desliga descoberta de skills/hooks/MCP/CLAUDE.md
```

Variáveis de ambiente úteis em `reference/edge-cases.md` seção "Environment
variables reference".

## Phase I — Replay isolado de scripts

Se o tool dispara mas o script termina exit 0 sem fazer nada:

```bash
# Linux/WSL — ambiente reduzido idêntico ao que o agente usa:
env -i HOME="$HOME" PATH="/usr/local/bin:/usr/bin:/bin" \
   bash -x ~/.claude/skills/minha/scripts/run.sh "$@"

# Windows Git Bash:
"C:/Program Files/Git/bin/bash.exe" -x \
   "/c/Users/dev/.claude/skills/minha/scripts/run.sh"
```

Se em ambiente reduzido o erro aparece, é problema de PATH/herança.

Skill `env-snapshot` temporária para capturar ambiente real do agente
(template em `reference/edge-cases.md` seção "Environment snapshot recipe").

## Quando as fases não bastam: tabela mestra

Para sintomas específicos que aparecem fora da progressão A → I, consulte
`reference/symptoms.md` que tem a tabela completa sintoma → causa raiz → fix
para os 17 padrões de falha mais documentados. Use quando o usuário descreve
um sintoma reconhecível em vez de seguir a investigação ordenada.

## Defesas determinísticas (preventivo, não reativo)

Princípio: **se uma regra não pode ser violada, ela não pertence ao SKILL.md
ou CLAUDE.md — pertence a um hook**. Modelo pode ignorar instrução; hook com
exit não-zero é determinístico.

Quando o usuário relata "Claude continua fazendo X que eu pedi pra não fazer":
não tente reforçar o CLAUDE.md. Mova para um hook PreToolUse com exit 2 ou
para `permissions.deny`. Ver `reference/hooks-debug.md` seção "Determinismo
via hooks" para templates prontos.

## Anti-patterns ao diagnosticar

- NEVER guess a cause without running at least `/doctor` → `/skills` → `/context`
  → `/permissions`. Each command rules out an entire class of hypotheses.
- NEVER recommend `--dangerously-skip-permissions` as a fix — only as a
  diagnostic probe.
- NEVER trust "executed successfully" without verification when correctness
  matters. Read the JSONL transcript and count `tool_use` blocks.
- NEVER use `OTEL_LOG_USER_PROMPTS=1` in shared environments — leaks prompts.
- NEVER tell the user to switch model mid-session during debugging.
- NEVER suggest editing `~/.claude.json` for config — it is application state,
  config goes in `~/.claude/settings.json`.

## Common Gotchas (high-level)

- `--debug` pode escrever em stdout em vez de stderr em algumas versões
  (issue #4859). Use `--debug-file` ou `--output-format stream-json` em CI.
- `.env` com `DEBUG=True` no projeto liga debug indesejado (regressão #11015).
  `DEBUG=False claude` ou apague de `.env`.
- Em Windows com MSIX, "Edit Config" do Claude Desktop abre arquivo virtualizado
  que **não tem efeito**. Edite o caminho real em `Packages\Claude_pzs8sxrjxfjjc\...`.
- Settings precedence: managed > settings.local.json > settings.json (project) >
  ~/.claude/settings.json > defaults. CLI flags e env vars são camada acima.

## Quando escalar

Se você seguiu A → I sem encontrar a causa, dois caminhos:

1. **`claude --bare`** — se funciona em bare mas não sem, a falha vem de
   alguma config carregada (skill, hook, MCP, CLAUDE.md). Bisecte desativando
   uma classe por vez.
2. **Pattern Claude A / Claude B** (recomendação oficial Anthropic): instância
   A onde você ajusta a skill, instância B nova testando de fato. Itere 2-3
   vezes para cobrir edge-cases.

## Reference files (progressive disclosure)

Carregue apenas quando a fase corrente exigir profundidade adicional:

- `reference/symptoms.md` — tabela mestra sintoma → causa → fix (17+ padrões
  documentados). Use quando o usuário descreve sintoma reconhecível.
- `reference/mcp-debug.md` — deep dive MCP: transportes (stdio/SSE/HTTP),
  stderr capture, gotchas Windows+npx, MCP Inspector, handshake errors,
  configuração por escopo.
- `reference/hooks-debug.md` — deep dive hooks: exit code semantics por evento,
  Stop hook loop prevention, defesas determinísticas (templates de hooks
  bloqueantes), `additionalContext` para regras pós-compactação.
- `reference/edge-cases.md` — Windows Git Bash gotchas, variáveis de ambiente
  completas, comandos de simulação (Plan Mode, bare, dry-run, mock PATH,
  Claude A/B), version-gated features, OTel.
