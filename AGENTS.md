# SILÊNCIO — padrão de desenvolvimento

- Preservar história, progresso salvo e funcionalidades existentes. Caio é surdo: comunicação por escrita/celular, leitura labial quando o rosto estiver visível e sinais apenas quando apropriados. Não apresentar gestos aproximados como Libras validada.
- Para sprites, tiles e animações em pixel art, consultar `pxl-pixel-art` em `C:/Users/giovane/.codex/skills/pxl-pixel-art/SKILL.md`. O renderer é `node <skill>/bin/pxl.js`; usar o Node empacotado se o comando node do sistema falhar.
- Manter fontes editáveis `.px.js` em `tools/art/`, exportações aprovadas em `assets/` e prévias fora dos assets do aplicativo. Nunca adicionar a ferramenta inteira ao APK.
- Não substituir a direção artística existente automaticamente por pixel art. Compatibilizar perspectiva isométrica, paleta, escala, pivô dos pés, sombra, transparência e orientação antes de integrar.
- Animações: verificar todas as direções e quadros lado a lado; alternar apoio dos pés pela distância realmente percorrida. Colisão deve corresponder ao chão, independentemente da altura visual.
- Usar Superpowers conforme a tarefa: diagnóstico antes de corrigir, plano proporcional ao escopo, testes relevantes e evidência antes de declarar conclusão. Aprovações já dadas continuam válidas; não reiniciar discussões aprovadas nem apagar trabalho em andamento por exigência genérica de uma skill.
- Não copiar código ou assets de jogos comerciais de referência. Criar implementações e arte originais.
- Testar percursos e interações reais, preservar saves no Android e registrar claramente testes automatizados, testes manuais e limitações mobile.
- FreeLLMAPI e OmniRoute são ferramentas opcionais de desenvolvimento, nunca dependências do jogo. Não mudar configurações de IA globais nem enviar arquivos a outro provedor automaticamente.
