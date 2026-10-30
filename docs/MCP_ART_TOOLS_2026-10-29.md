# Conexões de autoria verificadas

- Blender 5.2.3 LTS aberto, PID observado 23876, extensão Blender Lab MCP 1.0.3, TCP local 9876. Consulta somente leitura retornou Cube, Camera e Light, sem arquivo salvo.
- Configuração Codex tinha `command` apontando para uma pasta, com espaços, sem argumentos. Corrigida para uv.exe, `run --directory C:/Users/giovane/.codex/ai-tools/blender-lab-mcp/mcp blender-mcp`. Backup: `C:/Users/giovane/.codex/config.toml.before-blender-20261029-170305.bak`.
- Servidor oficial obtido de https://projects.blender.org/lab/blender_mcp.git (HEAD observado dbbf836ad4b1025f14a2b3b504c43903f39e0b04), ambiente virtual isolado, 41 dependências instaladas. Inicialização MCP e listagem de ferramentas passaram.
- Relay Unity existente 1.0.12-build.100 respondeu ao cliente MCP e conectou ao editor 30856. Foram descobertas ferramentas de captura, console, comandos e geração. Nenhuma geração paga nem alteração da cena foi executada.
- A lista nativa de ferramentas desta conversa não recebeu essas conexões dinamicamente. O acesso via cliente MCP local foi testado; uma nova sessão do Codex deve reler a configuração corrigida.

Esta verificação resolve acesso às ferramentas. Não comprova correção visual do jogo, criação de novos assets, funcionamento de cortinas/vidros nem conclusão da Fase 01.
