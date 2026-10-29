# Ferramentas de IA — instalação de 28/10/2026

## Atualização — roteadores configurados

O estado abaixo registra a instalação inicial. Depois, o FreeLLMAPI foi iniciado e o OmniRoute foi compilado no Docker e validado. Ambos aguardam provedores pessoais. O estado atual e as instruções estão em [ROTEADORES_IA.md](ROTEADORES_IA.md); dois perfis opcionais do Codex foram adicionados, sem mudar o provedor padrão.

## Registro inicial

## Estado real

| Ferramenta | Resultado |
|---|---|
| Superpowers | 15 skills locais instaladas para o usuário; sem hooks ou extensão nativa duplicada. |
| Caveman | Skill de respostas curtas instalada. CLI/proxy/cloud não instalados. Ativar com `$caveman`; desativar com `stop caveman`. |
| PXL | Link corrigido para `crsolver/claude-pxl`. CLI e 59 testes passaram; exportação de uma chave e animação original de seis quadros verificada. |
| FreeLLMAPI | Portátil 0.16.11 instalado em `C:/Users/giovane/.codex/ai-tools/freellmapi-0.16.11`. SHA-256 confere com o digest do release GitHub. Ainda não iniciado, sem provedores e sem teste de inferência. |
| OmniRoute | Apenas código-fonte do fork solicitado baixado, commit registrado no manifesto. Instalação pendente: engines Node >=18 <24; runtime disponível 24.22.1 e Docker parado. Não instalado outro runtime, não substituído pelo pacote npm de outro mantenedor. |

## Escopo global

As skills ficam em `C:/Users/giovane/.codex/skills`, com junctions de descoberta em `C:/Users/giovane/.agents/skills`. São globais para este usuário Windows, não para outros usuários, máquinas, celular ou servidores. Ficam disponíveis no próximo turno; se o seletor não atualizar, reabra o Codex.

Preferências persistidas em `C:/Users/giovane/.codex/AGENTS.md`. O padrão específico do jogo está em `AGENTS.md` na raiz do SILÊNCIO. Não foi alterado `config.toml`, login, modelo, provedor, PATH do sistema ou inicialização automática. Regras do usuário/projeto continuam superiores às sugestões genéricas das skills.

## Usar no jogo

Na raiz do SILÊNCIO:

```powershell
.\tools\pxl.cmd build tools/art/qa-pxl.px.js --out docs/qa-pxl
.\tools\pxl.cmd serve tools/art/qa-pxl.px.js --port 4321 --out docs/qa-pxl
```

O segundo comando abre um servidor de prévia local; termine com Ctrl+C. As fontes de teste estão em `tools/art`; nenhuma arte do teste foi adicionada ao runtime ou ao APK. A prévia tem uma figura deliberadamente simplificada para validar exportação e quadros; não substitui a animação final de Caio.

Para abrir FreeLLMAPI manualmente: executar `C:/Users/giovane/.codex/ai-tools/Abrir-FreeLLMAPI.cmd`. Adicionar suas próprias chaves de provedores pelo painel, observando as cotas de cada serviço. Não colar chaves no chat. Nenhuma credencial do Codex foi importada. FreeLLMAPI documenta `/v1/responses` para Codex CLI; a compatibilidade de inferência local ainda depende da configuração e de teste real. Não foi alterado o provedor desta conversa.

## Economia

Superpowers organiza o trabalho, mas planos, revisões e agentes também consomem tokens. Caveman encurta respostas; os números do autor não constituem medição deste projeto nem garantia sobre cota ChatGPT. PXL evita a dependência de geração de imagem externa para arte procedural, porém escrever/revisar a arte ainda consome trabalho da IA. Os gateways roteiam cotas de contas/provedores que você configurar; não criam crédito, não tornam qualquer modelo gratuito e não aumentam a cota da assinatura ChatGPT. Não há economia medida ainda nesta instalação.

## Fontes

- https://github.com/obra/superpowers
- https://github.com/JuliusBrussee/caveman
- https://github.com/crsolver/claude-pxl
- https://github.com/tashfeenahmed/freellmapi/blob/main/docs/en/install/01-install.md
- https://github.com/ChrisCompton/omniroute/blob/main/package.json
- https://learn.chatgpt.com/docs/build-skills
- https://developers.openai.com/plugins/guides/submit-claude-plugin

Manifesto com hashes/commits: `C:/Users/giovane/.codex/ai-tools/installation-status.json`.
