# Symptom Reference Table

Tabela mestra para casos onde o usuário descreve um sintoma reconhecível. Use
em vez do playbook A→I quando o sintoma for específico o suficiente para
mapear direto para causa raiz.

## Discovery failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Skill ausente em `/skills` | Arquivo solto `<nome>.md` em vez de pasta `<nome>/SKILL.md` | Mover para estrutura de diretório |
| Skill ausente, pasta correta | Frontmatter YAML inválido (vírgula, aspas, indent) | `head -10 SKILL.md` deve abrir e fechar com `---`; valide com YAML linter |
| Skill aparece em um repo, não em outro | Diretório criado **depois** do início da sessão | Saia (`exit`) e relance `claude` |
| `--add-dir` aponta correto, skill não carrega | Esperando que `agents/` ou `commands/` carreguem também | Apenas `.claude/skills/` é descoberto via `--add-dir` |
| CLI usa nome errado | Pasta com maiúsculas, espaços, ou caracteres não-ASCII | `name:` exige `[a-z0-9-]{1,64}`. Renomeie pasta E frontmatter |
| Skills em `.claude/skills/<name>.md` | Listagem vazia mesmo com sintaxe correta | Skill exige diretório, não arquivo solto |

## Routing failures (skill listada mas não invocada)

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Skill listada, modelo nunca aciona | Description vaga ou sem palavras-chave do usuário | Reescrever description com triggers explícitos; testar `/skill-name` manual |
| Skill listada, badge "user-only" | `disable-model-invocation: true` setado | Confirmar se foi intencional; senão, remover |
| Skill aparece em `/skills` mas não em `/context` | Budget de chars excedido (1.536/skill) | `SLASH_COMMAND_TOOL_CHAR_BUDGET=20000` ou encurtar description |
| Skill ativa em inglês, não em PT-BR | Description sem gatilhos PT-BR | Adicionar gatilhos PT-BR entre aspas dentro da description em inglês |

## Context lifecycle failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Skill funcionou, parou após muitas trocas | Auto-compact descartou (orçamento 25k tokens, 5k/skill) | Re-invocar manualmente; reduzir tamanho da skill; `context: fork` para isolar |
| Skill com instrução crítica é ignorada após compact | Mesma causa — instrução não persiste | Mover regra para hook PreToolUse com `additionalContext` |
| Modelo "esqueceu" SKILL.md em turn N+10 | Skills não são relidas — entram uma vez como mensagem | Por design. Re-invoque ou use hook |

## Permission and sandbox failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Tool permitido manualmente, mas pelo skill não | Permissions `Skill(...)` separadas das tools | `Skill(<name>)` ou `Skill(<name> *)` em `permissions.allow` |
| Skill grava em si mesma e falha | v2.1.38+ bloqueia writes em `.claude/skills/` sob sandbox | Mover artefatos para outra pasta; ou desligar sandbox |
| Tool funciona com `--dangerously-skip-permissions`, falha sem | Pura permissão | Ajuste `~/.claude/settings.json`; nunca mantenha o flag |
| `printenv FOO` funciona, `${FOO}` expande vazio | Issue #32512 — variável não exportada ou em arquivo errado | `export FOO=...` em `~/.bash_profile` (Windows Git Bash) |
| Skill falha "Operation not permitted" no /tmp | Sandbox: write apenas em cwd | `sandbox.filesystem.allowWrite` em `.claude/settings.json` |
| docker/watchman/podman trava | Incompatível com sandbox (Unix sockets) | Mover para `excludedCommands` |

## MCP failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| MCP server "0 tools" connected | initialize ok, tools/list falhou silenciosamente | `claude --debug mcp`, leia stderr |
| MCP `spawn ENOENT` | PATH do Claude Code menor que o do shell (Nix, asdf, nvm) | Path absoluto no `command`; ou wrapper `/bin/sh -c` |
| Project `.mcp.json` "não aparece" | Aprovação one-time foi dispensada | Aprovar via `/mcp` |
| Variáveis em `settings.json > env` ignoradas em MCP | env não propaga para subprocess MCP | Definir `env` por server em `.mcp.json` ou `claude mcp add --env` |
| Windows + npx falha "Connection closed" | npx em Windows precisa wrapper | `claude mcp add --transport stdio meu-srv -- cmd /c npx -y @org/srv` |
| Output truncado em ~10k tokens | Limite default 25k, warning a partir de 10k | `MAX_MCP_OUTPUT_TOKENS=50000` |
| Erro `-32602` na inicialização | Servidor enviou sampling/elicitation para client sem capability | Inspecionar troca `initialize` no log |
| Caminho relativo em `.mcp.json` | cwd não é o do `.mcp.json`, é onde lançou `claude` | Use **paths absolutos** sempre |
| `claude_desktop_config.json` sem efeito no Windows | MSIX virtualization (issue #26073) | Editar `Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\` |

## Hook failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Hook nunca dispara | `matcher` é JSON array em vez de string | `"matcher": "Edit\|Write"` (string com pipe) |
| Hook nunca dispara | Tool name lowercase (`"bash"`) | Capitalizado: `Bash`, `Edit`, `Write` |
| Hook nunca dispara | Em arquivo `.claude/hooks.json` standalone | Sob chave `"hooks"` em `settings.json` |
| Permissões ignoradas | Configuradas em `~/.claude.json` | Devem estar em `~/.claude/settings.json` |
| Settings ignoradas | `settings.local.json` sobrescreve | Por design: precedência `local > project > user > defaults` |
| Hook bloqueia mas não desfaz ação | Exit 2 em PostToolUse (já executou) | Mover para PreToolUse |
| Stop hook loop infinito | Exit 2 sem checagem de `stop_hook_active` | `[ "$STOP_ACTIVE" = "true" ] && exit 0` |
| "Hook Error" falso, exit 0 com JSON | Stdout contém output extra de perfis de shell | Stdout só com JSON; testar isoladamente |

## Telemetry and execution failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| `--debug` polui stdout em pipe | Bug em algumas versões (issue #4859) | `--debug-file` ou `--output-format stream-json` |
| `.env` com `DEBUG=True` liga debug indesejado | Regressão #11015 (lê `.env` do projeto) | `DEBUG=False claude` ou apague de `.env` |
| `tool_use` órfão (sem `tool_result`) | OOM ou loop infinito no Bash matou cliente | Inspecionar transcript JSONL; reduzir batch; aumentar timeout |
| Bash falha "ENOENT" no Windows | `npx`/`python` não encontrado, PATH do agente difere | `cmd /c npx ...` ou path absoluto; PATH em `settings.json > env` |
| Output Format Drift | JSON vira Markdown solto após muitos turns | `"strict": true` no schema; reforçar contrato no prompt |

## Hallucination failures

| Sintoma | Causa raiz | Fix |
|---|---|---|
| Tool-use hallucination — relatou ação sem chamar tool | Comum em `bypassPermissions`; falta ciclo de feedback | `--verbose` para confirmar `tool_use` blocks; PostToolUse hook que valida estado real |
| Modelo "pretende" rodar tool inexistente | Confira `/skills` e `/permissions`; se MCP, `/mcp` deve listar com prefix `mcp__<server>__<tool>` | Reconnect MCP; verificar nome exato |
| Error Swallowing — exceções viram "desafios em andamento", agente inventa dados | Falta validação determinística | PostToolUse hook que valida exit codes; `--max-turns` baixo |
| Skill "executou com sucesso" sem fazer nada | LLM "executou mentalmente" os passos | `--verbose` para ver `tool_use` blocks; reforçar description com verbos imperativos ("EXECUTE", "RUN"); usar `allowed-tools` para pré-aprovar |

## Decisão rápida: qual fase corresponde ao sintoma

- "Não aparece em `/skills`" → Phase B
- "Aparece mas modelo nunca chama" → Phase D
- "Funcionou, parou depois de várias trocas" → context lifecycle (acima)
- "Hook não está bloqueando" → Phase G + `reference/hooks-debug.md`
- "MCP server connected mas sem tools" → Phase F + `reference/mcp-debug.md`
- "Funciona num repo, falha em outro" → Phase E (sandbox/permissions) + variáveis de ambiente em `reference/edge-cases.md`
- "Disse que executou mas não fez nada" → Phase H (transcripts) + tabela hallucination acima
