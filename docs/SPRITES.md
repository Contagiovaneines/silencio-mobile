# Recursos visuais e sprites

Fonte do autor: `C:/Users/giovane/Documents/SILENCIO_GAME_ASSETS/SILENCIO_GAME_ASSETS`. Originais preservados. Registro de cada cópia e SHA-256: `ASSETS_INTEGRADOS.json`.

## Contratos em uso

- Retratos/poses legadas: PNG RGBA 128 × 128 quando declarado no respectivo manifesto; não aplicar esta medida aos atlas atuais de Caio.
- Caio: atlas RGBA com células de 128 × 144, pivô de apoio (64,119), render a 80 × 90 com nearest-neighbor. Idle tem 4 colunas; caminhada/corrida têm 6. Colisor separado nos pés.
- Ordem das linhas dos atlas de Caio: E, SE, S, SW, W, NW, N, NE, segundo a projeção isométrica do jogo. A passada avança pela distância realmente percorrida.
- Corrida com mochila: a normalização por quadro é produzida por `tools/art/build_actor_sources.py` e `tools/art/actor_skins.px.js`; não reutilizar um mapa fixo de espelhos por linha. A saída aprovada está em `assets/images/actors/actor_caio_run.png`.
- Locomoção sem mochila: caminhar/correr usa a mesma escala de corpo por quadro, preparada por `nobag_locomotion_cells` em `tools/art/build_actor_sources.py`; a pose aérea da corrida pode levantar os pés sem mudar o pivô declarado.
- Direções: a tabela única de apresentação é `lib/game/sprite_facing.dart`, com mapeamentos próprios de caminhada/poses e corrida. Algumas vistas são espelhadas provisoriamente.
- Animais: PNG 96 × 96, seis quadros SE; apoio aproximado no ponto (48,88).
- Veículos: PNG 512 × 320, estados fechado/aberto; colisor de chão definido no mapa, sem incluir a transparência.
- Tiles: PNG 64 × 32 sobre os losangos isométricos; madeira, concreto, calçada, asfalto e grama.
- Objetos de mundo: cópias de `05_ITENS_ARMAS/world`, e não os ícones de inventário.
- Retratos: fundos opacos preservados; apresentados apenas na interface.

O manifesto de recursos adicionais é `assets/data/phase_assets.json`; `assets/data/asset_pack_v1.json` registra os atlas e metadados de produção. As cópias planas em `assets/images` permitem empacotar Android e web pelo mesmo contrato.

## Geometria e colisão

Edifícios, portas, móveis e veículos têm áreas explícitas. O renderer recebe o tipo e a altura do móvel, evitando interpretar estilos pela posição na lista. A colisão usa a área do chão; o desenho elevado e a ordenação não alteram essa área. A navegação verifica os segmentos para não atravessar paredes entre duas células livres.

Paredes, mobiliário e abertura ainda usam desenho no motor, com aparência provisória. Os placeholders originais permanecem disponíveis no projeto e no gerador, mas não representam o elenco final. Não executar o gerador de placeholders para substituir a arte integrada.

Para saber o que é pose, ciclo ou animação pendente, consulte `ANIMACOES_FASE_01.md`. Prévias do pacote e storyboards não são capturas desta build nem atlas prontos.
