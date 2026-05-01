# Edge Cases Reference

Gotchas de ambiente, variáveis, simulação e features versionadas. Carregado
quando o playbook principal indica que o problema é específico a Windows,
PATH, ou requer estratégias de teste avançadas.

## Windows 11 com Git Bash (caso `pc-nery` / user `dev`)

### Caminhos canônicos

| Recurso | Caminho |
|---|---|
| Skills globais | `C:\Users\dev\.claude\skills\<nome>\SKILL.md` |
| Settings global | `C:\Users\dev\.claude\settings.json` |
| Debug logs | `C:\Users\dev\.claude\debug\<session-id>.txt` |
| Transcripts | `C:\Users\dev\.claude\projects\<cwd-hash>\<sid>.jsonl` |
| Managed | `C:\Program Files\ClaudeCode\managed-settings.json` (legado `C:\ProgramData\` removido em v2.1.75) |
| Git Bash | `C:\Program Files\Git\bin\bash.exe` |
| MCP Desktop config (real, MSIX) | `C:\Users\dev\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json` |
| MCP Desktop config (virtualizado) | `C:\Users\dev\AppData\Roaming\Claude\claude_desktop_config.json` |

### Crítico: CLAUDE_CODE_GIT_BASH_PATH

Aponta para `bash.exe`, **NUNCA** para `git.exe`:

```powershell
$env:CLAUDE_CODE_GIT_BASH_PATH="C:\Program Files\Git\bin\bash.exe"
```

Issues #4507, #8674, #25593, #47923 confirmam que mesmo com Git Bash instalado,
paths com espaços ou usuários novos do Windows podem quebrar a detecção.

### PowerShell tool nativo

```powershell
$env:CLAUDE_CODE_USE_POWERSHELL_TOOL=1
# E no SKILL.md:
# shell: powershell
```

PowerShell tool ainda é rollout progressivo no Windows mesmo na v2.1.x.

### Comandos PowerShell úteis para debug

```powershell
# Tail do debug log mais recente:
Get-Content "$env:USERPROFILE\.claude\debug\$(Get-ChildItem $env:USERPROFILE\.claude\debug | Sort LastWriteTime -Desc | Select -First 1).Name" -Wait -Tail 30

# Setar verbose e debug:
$env:CLAUDE_CODE_DEBUG_LOG_LEVEL="verbose"
$env:CLAUDE_CODE_GIT_BASH_PATH="C:\Program Files\Git\bin\bash.exe"
claude --debug "api,mcp,hooks"
```

### Em Git Bash

```bash
tail -F ~/.claude/debug/*.txt &
ls ~/.claude/projects/*/$(jq -r '.session_id' ~/.claude/.last_session 2>/dev/null || echo "*").jsonl
```

### Issue #32512 — `printenv FOO` funciona, `${FOO}` expande vazio

Causas possíveis:
1. Variável não foi exportada (`export FOO=...` em vez de só `FOO=...`)
2. Setada em arquivo que o shell de Claude não lê. No Windows com Git Bash,
   `~/.bashrc` é lido apenas em sessões interativas; defina em `~/.bash_profile`
   ou no nível de sistema do Windows.
3. Algum `apiKeyHelper` ou wrapper restaurou variáveis depois.

## Linux nativo / WSL2

| Recurso | Caminho |
|---|---|
| Skills globais | `~/.claude/skills/<nome>/SKILL.md` |
| Settings | `~/.claude/settings.json` |
| Debug | `~/.claude/debug/<session-id>.txt` |
| Transcripts | `~/.claude/projects/<cwd>/<sid>.jsonl` |
| Managed | `/etc/claude-code/managed-settings.json` |

Sandbox requer bubblewrap:
```bash
sudo apt install bubblewrap   # Debian/Ubuntu
sudo dnf install bubblewrap   # Fedora
```

**WSL1 não suporta sandbox**. WSL2 sim.

Em WSL2, atenção a cwd: trabalhar em `/mnt/c/...` é lento (filesystem 9P).
Prefira `~/projetos/...` em ext4.

## Environment variables reference

### Debug e logging

| Variável | Efeito |
|---|---|
| `ANTHROPIC_LOG=debug` | Logs detalhados de API |
| `CLAUDE_CODE_DEBUG_LOG_LEVEL` | `verbose\|debug\|info\|warn\|error` |
| `CLAUDE_CODE_DEBUG_LOGS_DIR` | Caminho de **arquivo** para debug log (apesar do nome) |
| `CLAUDE_CODE_BRIEF=0` | Restaura output detalhado em vez de "Read 3 files" |
| `CLAUDECODE=1` | Setado por Claude Code em todo subprocesso Bash |

### Comportamento de Bash

| Variável | Efeito |
|---|---|
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` | Volta para cwd original após cada `cd` |
| `BASH_DEFAULT_TIMEOUT_MS=120000` | Timeout default do tool Bash (2 min) |
| `BASH_MAX_TIMEOUT_MS=600000` | Teto que o modelo pode pedir (10 min) |
| `BASH_MAX_OUTPUT_LENGTH` | Antes do truncamento middle |
| `CLAUDE_CODE_SHELL_PREFIX` | Wrapper em todo Bash (auditoria) |
| `CLAUDE_ENV_FILE=/path/init.sh` | Script sourced antes de cada Bash |

### MCP

| Variável | Efeito |
|---|---|
| `MCP_TIMEOUT=30000` | Startup de servidor MCP |
| `MCP_TOOL_TIMEOUT=100000000` | Execução de tool MCP (default ~28h) |
| `MAX_MCP_OUTPUT_TOKENS=25000` | Default; warning a partir de 10.000 |
| `MCP_CONNECTION_NONBLOCKING=true` | Não bloquear primeira query em headless |
| `MCP_SERVER_CONNECTION_BATCH_SIZE` | Default 3 (stdio) |
| `MCP_REMOTE_SERVER_CONNECTION_BATCH_SIZE` | Default 20 (remote) |

### Segurança e isolamento

| Variável | Efeito |
|---|---|
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` | Remove `ANTHROPIC_*`, AWS/GCP/Azure de subprocessos |
| `CLAUDE_CODE_SCRIPT_CAPS=10` | Limita invocações de script por sessão |

### Skills e contexto

| Variável | Efeito |
|---|---|
| `SLASH_COMMAND_TOOL_CHAR_BUDGET=20000` | Budget de chars na listagem de skills |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Limite de auto-compactação (default ~95%) |
| `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` | Não grava transcripts |

### Plataforma

| Variável | Efeito |
|---|---|
| `CLAUDE_CODE_GIT_BASH_PATH` | **Crítico no Windows** — path absoluto para bash.exe |
| `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` | Habilita PowerShell tool nativo |
| `CLAUDE_CONFIG_DIR=~/.claude-trabalho` | Redireciona inteiramente o diretório de config (múltiplas contas) |

### OpenTelemetry

| Variável | Efeito |
|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY=1` | Liga OTel |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Endpoint OTLP (ex: `http://localhost:4318`) |
| `OTEL_LOG_TOOL_DETAILS=1` | Args dos tools nos traces |
| `OTEL_LOG_TOOL_CONTENT=1` | Conteúdo (cuidado com PII) |
| `OTEL_LOG_USER_PROMPTS=1` | Texto do prompt (NUNCA em ambiente compartilhado) |

Spans relevantes: `claude_code.interaction`, `claude_code.tool`,
`claude_code.tool.execution`, `claude_code.hook`. Subprocessos Bash herdam
`TRACEPARENT` automaticamente.

## Estratégias de simulação

### Plan Mode

```bash
claude --permission-mode plan
# Ou Shift+Tab para ciclar entre default/acceptEdits/plan/auto/bypassPermissions
```

Modelo só lê — não executa Bash, não modifica arquivos. Útil para "compilar
mentalmente" o que a skill fará. Em Plan Mode, hooks `PreToolUse` ainda
disparam para tools de leitura, mas tools de escrita são bloqueadas antes
de chegar ao hook.

### Headless com limites

```bash
claude -p --max-turns 5 "/minha-skill"            # limita profundidade
claude -p --max-budget-usd 2 "/minha-skill"       # limita custo
claude -p --output-format json "/minha-skill"     # bloco final estruturado
claude -p --output-format stream-json --verbose --include-hook-events --include-partial-messages
```

Stream-json em CI:

```bash
claude -p "/minha-skill" \
  --output-format stream-json --verbose \
  --include-hook-events --include-partial-messages \
  > run.ndjson 2>&1

jq -c 'select(.type=="tool_result") | {tool:.tool_name, error:.is_error, out:.content}' run.ndjson
```

### Bare mode (isolamento total)

```bash
claude --bare -p "/minha-skill"
```

Desliga descoberta de skills, hooks, MCP, CLAUDE.md. Diagnóstico definitivo:
se funciona em bare mas falha sem, a falha vem de alguma config carregada.
Bisecte desativando uma classe por vez.

### Dry-run por convenção

Skills destrutivas devem aceitar `apply` como segundo argumento e tratar
default como dry-run:

```yaml
---
name: deploy
description: Deploy to prod. Default is dry-run unless argument is "apply".
disable-model-invocation: true
arguments: [target, mode]
argument-hint: "[staging|prod] [dry-run|apply]"
---
Run: `./scripts/deploy.sh "$0" "${1:-dry-run}"`
If `mode != "apply"`, NEVER call external APIs; only print what would be done.
```

E no script:

```bash
[[ "$2" == "apply" ]] || { echo "DRY RUN"; exit 0; }
```

### Mock via PATH injection

Isolar skill de side-effects reais (gh CLI, docker, kubectl):

```bash
export TEST_TEMP_DIR="$(mktemp -d)"
# Criar binários falsos em $TEST_TEMP_DIR (ex: gh, docker, kubectl)
cat > "$TEST_TEMP_DIR/docker" <<'EOF'
#!/bin/bash
echo "MOCK docker called with: $@"
exit ${MOCK_DOCKER_EXIT:-0}
EOF
chmod +x "$TEST_TEMP_DIR/docker"

export PATH="$TEST_TEMP_DIR:$PATH"
export MOCK_DOCKER_EXIT=0

# Agora rode a skill — ela vai chamar o docker mock em vez do real
claude -p "/minha-skill"
```

### Pattern Claude A / Claude B (recomendação oficial Anthropic)

- **Claude A**: instância onde você desenha e refina o `SKILL.md`.
- **Claude B**: instância nova, com a skill instalada, executando tarefa real.
- Observe o que Claude B faz e leve as observações de volta a Claude A.
- Iterar 2-3 vezes geralmente cobre os edge-cases mais comuns.

### Environment snapshot recipe

Skill temporária para capturar PATH/env real do agente:

```yaml
---
name: env-snapshot
description: Capture PATH and env that the agent actually sees
disable-model-invocation: true
allowed-tools: Bash(env *) Bash(echo *) Bash(which *)
---
Capture:
- PATH: !`echo $PATH`
- HOME: !`echo $HOME`
- CLAUDECODE: !`echo "$CLAUDECODE"`
- shell: !`readlink -f /proc/$$/exe 2>/dev/null || ps -p $$ -o comm=`
- env (non-secret): !`env | grep -Ev 'KEY|TOKEN|SECRET|PASSWORD' | sort`
```

A injeção `` !`...` `` roda **antes** do contexto entrar — você vê o ambiente
real, não o que o modelo "acha".

Depois de capturar, rode o script com env idêntico:

```bash
env -i $(cat /tmp/claude_env.txt) bash scripts/run.sh
```

## Inspeção de transcript JSONL

```bash
# Listar projetos:
ls ~/.claude/projects/

# Cada sessão é um JSONL:
ls ~/.claude/projects/-Users-dev-meu-projeto/*.jsonl

# Filtrar tool_use e tool_result:
jq -c 'select(.type=="tool_use" or .type=="tool_result")' \
   ~/.claude/projects/-Users-dev-meu-projeto/<session-id>.jsonl

# Estatística de eventos:
jq -c '.type' file.jsonl | sort | uniq -c

# Errors:
jq 'select(.type=="tool_result" and .is_error==true)' file.jsonl

# Frequência de uma tool:
grep '"name":"Write"' ~/.claude/projects/<project>/*.jsonl | wc -l
```

## Version-gated features

Várias afirmações são versionadas — Claude Code evolui rápido (release semanal/quinzenal):

| Feature | Versão mínima |
|---|---|
| `/debug` bundled skill | v2.1.30 |
| Block de writes em `.claude/skills/` sob sandbox | v2.1.38 |
| Path Windows legado removido (`C:\ProgramData\ClaudeCode\`) | v2.1.75 |
| `defer` em PreToolUse | v2.1.89 |
| Exemption do `--dangerously-skip-permissions` para `.claude/{skills,agents,commands}/` | v2.1.121 |
| SSE transport deprecated (sai 2026-04-01) | — |

Sempre rode `claude --version` e `claude doctor` antes de aplicar receitas.
O fato de um flag não aparecer em `claude --help` **não** significa que ele
não exista — a documentação oficial (`code.claude.com/docs/en/cli-reference`)
tem a tabela completa, frequentemente mais ampla que `--help`.

## Segurança durante debug

- **Nunca logue stdout direto** de comandos que possam conter `$ANTHROPIC_API_KEY`
  ou tokens MCP. Use `env | grep -Ev 'KEY|TOKEN|SECRET|PASSWORD'`.
- Em ambientes compartilhados ou CI, ative `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`.
- OTel: por padrão **redige** prompts e tool details. Só ative
  `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT`
  em ambiente confiável.
- Para usar a assinatura paga sem cobrança via API: `unset ANTHROPIC_API_KEY`
  (em `claude -p` a chave **sempre** é usada quando presente). Verifique com
  `/status` ou `claude auth status`.
- Em settings, prefira `apiKeyHelper` apontando para script que lê secret
  manager, em vez de chave em `.env`.
- **Não edite** `~/.claude.json` para colocar segredos: ele **não é** o local
  seguro de credenciais (Keychain no macOS, `.credentials.json` no
  Linux/Windows com permissão restritiva). Adicione `~/.claude.json` ao
  `.gitignore` global.
