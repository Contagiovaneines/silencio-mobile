# Assets e capítulo 02 — 29/10/2026

## Arte integrada

Pacote original: 33 peças de arquitetura/objetos e 43 pranchas de personagens, com 2.160 células. As pranchas têm oito posições de direção, transparência, pivô dos pés (64,119) e células de 128×144. Caio usa os seis quadros originais de caminhada/corrida por direção. NPCs usam vistas frontais e posteriores próprias; direções próximas compartilham vistas e algumas são espelhadas. Não são oito desenhos independentes de cada pose.

O jogo seleciona caminhada pela distância percorrida. Ataque e dano usam progresso da ação. Defesa frontal reduz dano de 12 para 3 e consome vigor; ataques pelas costas continuam causando dano integral. Tecla V ou botão Defender. Mirar/defender permite deslocamento lateral e recuo mantendo a orientação.

Paredes têm revestimentos, janelas abertas/fechadas/quebradas, portas e batentes. Há móveis, pia, vaso, chuveiro, elevador, escadas e cobertura. O renderer usa o revestimento das fachadas, paredes, janelas, elevador e novos móveis comerciais. Móveis e peças de banheiro de maior detalhe já existentes foram preservados. Portas animadas, escadas e telhados continuam com geometria própria para coincidir com as aberturas e colisões; os sprites alternativos estão exportados, sem substituir automaticamente essas partes.

Fontes: `tools/art/building_kit.px.js`, `actor_cycles.px.js`, `actor_skins.px.js`; imagens originais complementares em `tools/art/source/npc_views`. Nenhum código ou sprite de Project Zomboid foi copiado. Ferramentas/fontes/previews ficam fora dos assets do aplicativo.

Revisão: `tools/art/out/asset-review/` contém pranchas completas e contatos por direção. `python tools/art/verify_asset_pack.py` verifica tamanho, transparência, células não vazias, variação e ausência de recorte nas bordas. Esse teste não substitui avaliação estética.

## Conferência com o PDF

Fonte: `SILENCIO_Historia_Completa_Fases_e_Dialogos.pdf`, páginas 10–13. O capítulo 02 é **02:00**; **A Queda** é o capítulo 03.

| Requisito da fase 01 | Estado |
|---|---|
| 07:12, celular, chave e adaptador | Implementado |
| Apartamento, escada, loja e TV | Percurso físico e interações existentes preservados |
| Vizinha opcional | Ajuda e consequência persistentes |
| Beco sem obrigar matar | Empurrão, recuo, portão e saída alternativa |
| Alavanca manual, pulso e mensagem noturna | Implementado |
| Retorno, cama, checkpoint e liberar 02:00 | Implementado; entrada explícita do capítulo 02 adicionada |
| Duração de 15–25 minutos | Meta do PDF; não aferida com jogador humano nesta revisão |

Não foi declarada equivalência cinematográfica quadro a quadro com o PDF. A implementação mantém o percurso e condições de conclusão; falas incidentais e apresentação podem variar.

## Capítulo 02 jogável

Após concluir a fase 01, usar **Jogar fase 02 · 02:00** na conclusão ou selecionar **02:00** em Jornada. A história e os eventos anteriores permanecem no mesmo save. Saves antigos sem o campo novo de vida do dominado continuam válidos.

Percurso: despertar 01:58, lanterna/kit, porta 203, painel com registro de desligamento remoto, escadas, garagem, disjuntor ou lata, saída residencial, celular de Helena, posto com mapa. A lanterna acompanha a direção de Caio e seu cone no chão para nos obstáculos. O dominado reage à distração; o alarme tem indicação visual. O resgate opcional custa uma atadura e tempo e dá a chave do portão. Sem resgate, o caminho por baixo do muro permanece transitável. Checkpoint antes do corredor e ao avançar nas interações.

Rádio/manutenção são apresentados por visor/texto e celular. A vizinha troca bilhetes pela porta; Caio escreve e faz um aceno comum, sem apresentar gestos inventados como Libras. Mensagem final não enviada: “Estou indo.” Capítulo 03 permanece em produção.

O posto é representado por ponto de serviço e mapa ao lado da oficina. O cenário reutiliza o bairro; não há um novo interior completo de oficina nesta fase.

## Verificação e limites

Os testes percorrem a fase 02 fisicamente, com e sem resgate, verificando colisões e recarga do save. Há teste de interface em 360×800 e 13 renders de apartamento, corredores, fachada, loja, combate, garagem noturna, lanterna e posto. A suíte completa final passou com **113 testes**. `flutter analyze` terminou sem problemas e o build web release terminou com sucesso. A prévia local em `http://127.0.0.1:58402/` respondeu HTTP 200, com 43 pranchas e 33 peças no catálogo; ferramentas de arte não foram empacotadas. Logs completos em `tools/art/out/` (`full-test.log`, `render-final.log`, `analyze.log`, `build-web.log`).

A revisão separada encontrou consumo duplicado de atadura no resgate e espelhamento duplicado do atlas do dominado. Ambos foram corrigidos. O teste de regressão demonstra que estoque de três ataduras termina em duas, sem curar Caio nem apagar seu ferimento. A animação do dominado usa a direção do atlas e só espelha o renderer antigo de fallback. A suíte final acima inclui essas correções.

O teste de retrato simula o tamanho de tela: não equivale a jogar num aparelho Android. Nesta revisão, saves reais Android não foram abertos, migrados ou apagados. Validação manual de desempenho e toque em aparelho continua necessária. Os ciclos de NPCs civis são derivados de poses e deformações offline; têm menos expressividade que os ciclos específicos de Caio e os golpes de Davi.
