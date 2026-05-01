# MCP Debug Reference

Deep dive em depuração de servidores MCP. Carregado quando Phase F do playbook
principal indica que o problema está em MCP.

## Comandos canônicos

```bash
claude mcp list                      # status de todos os servers configurados
claude mcp get <nome>                # detalhes do server, incluindo OAuth
/mcp                                 # dentro da sessão: status + tools + OAuth
/mcp                                 # use Reconnect se "0 tools"
claude --debug mcp                   # mostra stderr do server stdio em tempo real
claude --strict-mcp-config --mcp-config ./mcp.json   # ignora outras configs
```

## Stderr capture por transporte

Os três transportes têm caminhos de debug **diferentes**:

| Transporte | Como roda | Stderr capturado? | Como testar isolado |
|---|---|---|---|
| **stdio** | Subprocess local (npx, uvx, binário) | ✅ Sim, visível com `claude --debug mcp` | MCP Inspector ou `npx -y @org/server-x` manualmente |
| **SSE** *(deprecated, sai 2026-04-01)* | HTTP keep-alive | ❌ Não capturado pelo client | `curl -N https://host/sse` para ver streaming |
| **Streamable HTTP** | HTTP request/response, SSE opcional | ❌ Não capturado pelo client | `curl -X POST https://host/mcp -H 'Content-Type: application/json' -d '...'` |

**Regra absoluta para servidor stdio:** stderr only. Nunca escreva em stdout
em servidor stdio — corrompe JSON-RPC. Para logging em SSE/HTTP, use o próprio
servidor (não conta com captura pelo client).

## Padrões de falha conhecidos

### "Connection closed" no Windows com npx

```bash
# Errado:
claude mcp add --transport stdio meu-srv -- npx -y @org/srv

# Certo:
claude mcp add --transport stdio meu-srv -- cmd /c npx -y @org/srv
```

### `spawn ENOENT`

PATH do Claude Code é menor que o do shell do usuário (especialmente com
Nix, asdf, nvm). Solução defensiva — wrapper que loga PATH e env:

```json
{
  "mcpServers": {
    "diag": {
      "command": "/bin/sh",
      "args": ["-c", "echo $PATH > /tmp/claude_path.txt; env > /tmp/claude_env.txt; exec /caminho/real/server"]
    }
  }
}
```

Solução final: `command` com path absoluto. Nunca dependa do PATH.

### Caminho relativo em `.mcp.json`

cwd resolve a partir de **onde você lançou `claude`**, não da localização do
`.mcp.json`. **Use paths absolutos sempre.**

### Project-scoped server "não aparece"

`.mcp.json` versionado exige aprovação one-time. Se o prompt foi dispensado,
o server fica desabilitado até aprovação manual via `/mcp`.

### Variáveis de ambiente para servidores MCP stdio

Variáveis definidas em `settings.json > env` **NÃO** propagam para processos
MCP filhos. Defina no `env` dentro do `.mcp.json`:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["/abs/path/to/server/index.js"],
      "env": {
        "SERVER_API_KEY": "valor-aqui",
        "NODE_ENV": "production"
      }
    }
  }
}
```

Ou via CLI: `claude mcp add ... --env KEY=val`.

### Headers em transport stdio

`--header` só se aplica a sse/http. Em stdio use `--env`.

### Output truncado em ~10k tokens

Claude Code avisa a partir de 10.000 tokens; eleve com:

```bash
export MAX_MCP_OUTPUT_TOKENS=50000
```

### Erro `-32602` (Invalid params) na inicialização

Geralmente indica que o servidor enviou requisições de `sampling` ou
`elicitation` para um cliente que não declarou essa capability. Inspecione
a troca `initialize` no log:

```bash
grep -i "initialize\|capability\|handshake" ~/.claude/debug/<session-id>.txt
```

### Conexões em paralelo

Defaults: 3 stdio, 20 remotos. Ajuste com:

```bash
export MCP_SERVER_CONNECTION_BATCH_SIZE=5
export MCP_REMOTE_SERVER_CONNECTION_BATCH_SIZE=30
```

### Não bloquear primeira query em headless

```bash
export MCP_CONNECTION_NONBLOCKING=true
```

## MCP Inspector — testar fora do Claude Code

```bash
# Servidor local TypeScript/Node:
npx @modelcontextprotocol/inspector node path/to/server/index.js

# Servidor npm:
npx -y @modelcontextprotocol/inspector npx @modelcontextprotocol/server-filesystem /Users/user/Desktop

# Servidor Python:
npx @modelcontextprotocol/inspector python path/to/server.py
```

Inspector fornece:
- Painel de conexão: selecionar transporte (stdio / HTTP)
- Aba Resources: listar e inspecionar recursos disponíveis
- Aba Tools: invocar ferramentas com inputs customizados, ver resultados
- Painel Notifications: logs e notificações do servidor em tempo real

Use o Inspector **antes** de integrar ao Claude Code. Se a tool funciona no
Inspector mas falha no Claude Code, o problema está na integração (env,
PATH, permissions), não no servidor MCP.

## Configuração — onde fica o quê

| Escopo | Caminho | Quem lê |
|---|---|---|
| Project (versionado) | `<repo>/.mcp.json` | Claude Code, exige aprovação |
| User (global, Claude Code) | `~/.claude/settings.json` (`mcpServers`) ou `claude mcp add --scope user` | Claude Code |
| Claude Desktop (separado!) | macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`; Linux: `~/.config/claude-desktop/...`; Windows: `%APPDATA%\Claude\...` (mas MSIX virtualiza para `Packages\Claude_pzs8sxrjxfjjc\...`) | Claude Desktop apenas — **não compartilha com Claude Code** |
| Importação | `claude mcp add-from-claude-desktop` | Migra Desktop → Code |

## Logs do Claude Desktop (separado do Claude Code)

- macOS: `~/Library/Logs/Claude/mcp*.log`
- Windows: `%LOCALAPPDATA%\Claude\Logs\mcp*.log`
- Para acompanhar:
  - PowerShell: `Get-Content "$env:LOCALAPPDATA\Claude\Logs\mcp.log" -Wait -Tail 20`
  - WSL2: `tail -F /mnt/c/Users/dev/AppData/Local/Claude/Logs/mcp*.log`

## Checklist rápido quando MCP falha

1. `/mcp` mostra connected ou failed?
2. Se failed → `command` é path absoluto? Wrapper `cmd /c` no Windows?
3. Se connected mas 0 tools → Reconnect; se persistir, `claude --debug mcp` e leia stderr
4. Variáveis de ambiente: estão em `.mcp.json > env` (não em `settings.json > env`)?
5. Project `.mcp.json` foi aprovado via `/mcp`?
6. Output truncado? `MAX_MCP_OUTPUT_TOKENS`
7. Funciona no MCP Inspector mas não no Claude Code? Problema é integração, não servidor

## Timeouts MCP relevantes

```bash
export MCP_TIMEOUT=30000              # startup de servidor
export MCP_TOOL_TIMEOUT=100000000     # execução de tool (default ~28h)
```

Aumente `MCP_TIMEOUT` se servidor demora a inicializar (downloads, autenticação OAuth).
