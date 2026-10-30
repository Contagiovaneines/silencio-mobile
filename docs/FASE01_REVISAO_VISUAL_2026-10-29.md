# Revisão da Fase 01 — referência e estado

Pedido atual: concluir apresentação e jogabilidade da primeira fase antes de ampliar a segunda. Prioridade: visual, interiores/exteriores coerentes, móveis, animais, veículos, mapa e objetivos. Android permanece alvo; Caio é surdo conforme instrução direta do autor.

## Evidências consultadas nesta revisão

- PDF em Downloads, 48 páginas, páginas 10–11: apartamento às 07:12, escada, mercearia, rua comercial, beco, parada de ônibus, anomalia, mensagem noturna, retorno e salvamento. Combate e tarefa da vizinha são opcionais. O portão possui alavanca manual indicada pelo zelador. Conferir cada evento com a implementação antes de declarar fidelidade.
- Projeto antigo: `C:/Users/giovane/Downloads/Silencio-main/Silencio-main/project.godot` e `scripts/screens/world_map.gd`. Mapa de campanha com 12 capítulos, seleção limitada ao progresso e indicação de disponibilidade. Análise inicial de fonte, sem execução desta build.
- Mods: nove diretórios, incluindo 133 fontes Lua. O relatório prévio `MODS_ZOMBOID_2026-10-29.md` registra leitura focada e limitações REA. Nesta revisão foi confirmado o inventário por extensão e localizado o script de desmontagem de veículos. Não foi feita nova decompilação nem leitura integral.
- Ferramentas MCP de Blender/Unity não aparecem no catálogo disponível nesta sessão. Não alegar conexão ou execução nessas ferramentas.

## Alteração aplicada

Removidos seletor de destino, botão Caminhar até e método de navegação automática acionado pelo mapa. Mapa permanece informativo, com objetivo atual e acesso à Jornada. Movimento normal e aproximação de objetos permanecem sistemas independentes.

## Trabalho ainda necessário

1. Interiores/exteriores: revisar o recorte das paredes e a geometria compartilhada da fachada; eliminar aparência de plataforma isolada e portas sem parede coerente. Validar entrando e saindo, além das capturas offline.
2. Arte: revisar pivôs, escala e oclusão dos móveis; revisar todos os quadros e direções de animais e veículos antes de trocar assets.
3. Interações: projetar estados persistentes de vidro, janela e cortina, com distância, colisão, consequências e ações interrompíveis. Abrir janela já existe; quebrar vidro e retirar cortina não estão confirmados.
4. Missões: confrontar o percurso real com páginas 10–11, especialmente alavanca/portão, parada de ônibus, vizinha opcional e encerramento em casa. Manter exploração opcional sem avançar missão por presença indevida.
5. Mapa: melhorar legibilidade e objetivos aproveitando conceitos do projeto Godot; não transplantar scripts ou introduzir outra engine automaticamente.
6. QA: percurso completo no navegador, retorno ao menu, continuidade do save e regressões; desempenho Android só pode ser confirmado no aparelho.

Decisão técnica inicial: esses problemas pertencem ao layout, dados, renderização e estados existentes em Dart/Flame. Não há medição que justifique outra linguagem neste momento. Blender pode apoiar autoria offline quando houver acesso funcional; não é dependência do jogo.
