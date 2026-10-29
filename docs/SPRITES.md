# Recursos visuais e sprites

Fonte do autor: `C:/Users/giovane/Documents/SILENCIO_GAME_ASSETS/SILENCIO_GAME_ASSETS`. Originais preservados. Registro de cada cópia e SHA-256: `ASSETS_INTEGRADOS.json`.

## Contratos em uso

- Humanos: PNG RGBA 128 × 128, pivô de apoio (64,120), apresentação 80 × 80. Colisor separado nos pés.
- Caio: ciclos de seis quadros para caminhada/corrida; idle e ações usam poses específicas. A origem SE do nome não é usada como ângulo sem revisão.
- Direções: a tabela única de apresentação é `lib/game/sprite_facing.dart`, com mapeamentos próprios de caminhada/poses e corrida. Algumas vistas são espelhadas provisoriamente.
- Animais: PNG 96 × 96, seis quadros SE; apoio aproximado no ponto (48,88).
- Veículos: PNG 512 × 320, estados fechado/aberto; colisor de chão definido no mapa, sem incluir a transparência.
- Tiles: PNG 64 × 32 sobre os losangos isométricos; madeira, concreto, calçada, asfalto e grama.
- Objetos de mundo: cópias de `05_ITENS_ARMAS/world`, e não os ícones de inventário.
- Retratos: fundos opacos preservados; apresentados apenas na interface.

O manifesto de recursos adicionais é `assets/data/phase_assets.json`. As cópias planas em `assets/images` permitem empacotar Android e web pelo mesmo contrato.

## Geometria e colisão

Edifícios, portas, móveis e veículos têm áreas explícitas. O renderer recebe o tipo e a altura do móvel, evitando interpretar estilos pela posição na lista. A colisão usa a área do chão; o desenho elevado e a ordenação não alteram essa área. A navegação verifica os segmentos para não atravessar paredes entre duas células livres.

Paredes, mobiliário e abertura ainda usam desenho no motor, com aparência provisória. Os placeholders originais permanecem disponíveis no projeto e no gerador, mas não representam o elenco final. Não executar o gerador de placeholders para substituir a arte integrada.

Para saber o que é pose, ciclo ou animação pendente, consulte `ANIMACOES_FASE_01.md`. Prévias do pacote e storyboards não são capturas desta build nem atlas prontos.
