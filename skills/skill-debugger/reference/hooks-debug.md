# Hooks Debug Reference

Deep dive em depuração de hooks. Carregado quando Phase G do playbook indica
que o problema está em hook configuration ou semantics.

## Comandos canônicos

```bash
/hooks                # lista hooks ativos por evento
claude --debug hooks  # mostra cada decisão de matcher live
```

## Os três erros silenciosos clássicos

### 1. matcher como array em vez de string

```json
// ERRADO — silenciosamente descartado, sem warning:
"matcher": ["Edit", "Write"]

// CERTO — string com pipe:
"matcher": "Edit|Write"
```

### 2. Tool name em lowercase

Tool names são **case-sensitive**:
- ✅ `Bash`, `Edit`, `Write`, `Read`, `Grep`, `Glob`
- ❌ `bash`, `edit`, `write`

### 3. Hook em arquivo standalone

**Não existe** `.claude/hooks.json` standalone. Hooks vão sob a chave `"hooks"`
em `settings.json` (project ou user).

## Exit code semantics

| Exit Code | Efeito | JSON em stdout processado? |
|---|---|---|
| `0` | Sucesso, permite continuação | ✅ Sim |
| `2` | Erro bloqueante (em eventos bloqueantes) | ❌ Não |
| Outro | Erro não-bloqueante (log apenas) | ❌ Não |

## Exit 2 por evento — armadilha crítica

| Evento | Bloqueia? | Efeito do exit 2 |
|---|---|---|
| `PreToolUse` | ✅ | Bloqueia tool call antes de executar |
| `UserPromptSubmit` | ✅ | Rejeita e apaga o prompt |
| `Stop` | ✅ | Impede Claude de parar, continua a conversa |
| `PostToolBatch` | ✅ | Para o loop agêntico antes da próxima chamada ao modelo |
| `PostToolUse` | ❌ | Mostra stderr ao Claude (ferramenta **já executou** — não desfaz) |
| `StopFailure` | ❌ | Output e exit code são ignorados |
| `SessionEnd` | ❌ | Mostra stderr ao usuário apenas |

**Armadilha**: usuário quer "bloquear `rm -rf`", coloca em PostToolUse, vê o
hook disparar, mas o `rm -rf` já rodou. Sempre PreToolUse para bloqueio.

## Loop infinito em Stop hook

Stop pode re-disparar se o hook retornar exit 2 indefinidamente. Sempre cheque
`stop_hook_active`:

```bash
#!/bin/bash
INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0  # Evita loop
fi
# ... lógica do hook ...
```

## "Hook Error" falso

Versões anteriores marcavam erros mesmo quando hook retornava exit 0 com JSON
válido. Se o usuário relata "Hook Error" mas o exit está correto:

- Confirmar que stdout contém **somente** o JSON (sem output extra de perfis
  de shell, sem `set -x`, sem echo de debug).
- Testar isoladamente:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | bash seu-hook.sh
echo "Exit: $?"
```

Se há lixo no stdout do hook que vai além do JSON, o parser falha.

## Determinismo via hooks (regras inegociáveis)

Princípio: **se uma regra não pode ser violada, ela não pertence ao SKILL.md
ou CLAUDE.md — pertence a um hook**. Modelo pode ignorar instrução; hook com
exit não-zero é determinístico.

### Pattern: PreToolUse safety guard

```bash
#!/bin/bash
# .claude/hooks/safety-guard.sh
COMMAND=$(jq -r '.tool_input.command' < /dev/stdin)
DANGEROUS_PATTERNS="rm -rf|git push --force|kubectl delete|DROP TABLE|truncate"

if echo "$COMMAND" | grep -qiE "$DANGEROUS_PATTERNS"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Comando bloqueado pelo safety guard: padrão destrutivo detectado"
    }
  }'
  exit 0
fi
exit 0
```

Note: usa `permissionDecision: "deny"` em JSON com exit 0, **não** exit 2. Os
dois funcionam, mas o JSON dá uma mensagem mais clara ao Claude sobre por que
foi bloqueado.

### Pattern: PostToolUse para verificar estado real (anti-hallucination)

```bash
#!/bin/bash
# .claude/hooks/verify-execution.sh
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Para comandos git, verifica estado real após execução
if [[ "$TOOL_NAME" == "Bash" && "$COMMAND" =~ ^git ]]; then
  ACTUAL_STATUS=$(git status --short 2>/dev/null)
  jq -n --arg status "$ACTUAL_STATUS" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("Estado git real após comando: " + $status)
    }
  }'
fi
exit 0
```

### Pattern: persistir regra além da compactação via additionalContext

Quando uma regra precisa sobreviver a auto-compact (que pode descartar a
skill original):

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"Regra crítica: backup antes de modificar produção\"}}'"
      }]
    }]
  }
}
```

A cada PreToolUse, a regra é re-injetada no contexto. Não depende de skill
ainda estar carregada.

## Permissions deny — alternativa ao hook bloqueante

Para casos simples (sem regex complexo), `permissions.deny` é mais simples e
não requer script:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/credentials)",
      "Bash(git push --force *)",
      "Bash(rm -rf *)",
      "Bash(kubectl delete *)",
      "Bash(docker rm *)"
    ]
  }
}
```

Use deny rules para padrões estáticos. Use hook quando precisar de lógica
dinâmica (regex, validação contextual, decisão baseada em estado).

## Settings precedence (causa frequente de "hook ignorado")

Precedência (alta → baixa):

1. Managed (sistema): `/etc/claude-code/managed-settings.json` (Linux), `C:\Program Files\ClaudeCode\` (Windows), `/Library/Application Support/ClaudeCode/` (macOS)
2. Local (não versionado): `.claude/settings.local.json`
3. Project: `.claude/settings.json`
4. User: `~/.claude/settings.json`
5. Defaults

CLI flags e env vars são camada **acima** das settings.

**Causa frequente** de "minha config global é ignorada": usuário coloca em
`~/.claude.json` (que é estado de aplicação) em vez de `~/.claude/settings.json`.
São arquivos diferentes.

## Teste manual de hook

Simular input PreToolUse fora do agente:

```bash
echo '{
  "session_id": "test-123",
  "transcript_path": "/tmp/test-transcript.jsonl",
  "cwd": "/home/user/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf /tmp/old-build" }
}' | bash .claude/hooks/my-hook.sh

echo "Exit: $?"
```

Cheque:
- Exit code (0, 2, ou outro)
- Stdout contém JSON válido?
- Stderr tem mensagem útil?

## Checklist rápido quando hook não dispara

1. `matcher` é string com pipe (não array)?
2. Tool name está capitalizado (`Bash`, não `bash`)?
3. Hook está em `settings.json` sob chave `"hooks"` (não em `hooks.json` standalone)?
4. `settings.local.json` está sobrescrevendo? (Verifique precedência)
5. Permissões em `~/.claude.json` em vez de `~/.claude/settings.json`?
6. Script tem permissão de execução? (`chmod +x .claude/hooks/*.sh`)
7. `claude --debug hooks` — vê o matcher avaliando?

## Checklist rápido quando hook dispara mas não bloqueia

1. Está em PostToolUse? Mude para PreToolUse — PostToolUse não desfaz ação.
2. Exit code é 2 (e o evento suporta bloqueio)?
3. Se usa JSON em stdout: estrutura `hookSpecificOutput.permissionDecision: "deny"` está correta?
4. Stdout tem só o JSON, sem lixo?
