# Cama — sprites para interação

Estes quadros ainda serão produzidos. Não são vídeo de cutscene; o motor controla entrada, repouso e saída.

## Prompt

SILÊNCIO: jogo mobile em paisagem, cenário isométrico 2.5D com textura pintada e acabamento pixelizado discreto. Brasil contemporâneo, Santa Aurora. Exteriores azul-petróleo/cinza dessaturados, madeira e luz âmbar nos interiores. Preserve perspectiva, proporções e identidade das referências; não transformar em anime de luta, live-action ou 3D brilhante. Caio tem cabelo preto curto e bagunçado, jaqueta escura, mochila e aparência do retrato fornecido. Caio não fala nem narra. Não inventar diálogos, roupas, poderes, monstros, ferimentos ou acontecimentos. Sem HUD, palavras, legendas, marcas ou logotipos gerados; textos serão aplicados no jogo. Sem flashes repetidos, câmera trêmula, morphing, objetos duplicados ou mudança da planta. As capturas do beta contêm HUD: usar somente cenário e composição como referência, excluir toda a interface do resultado. Nunca gerar vídeo dentro de uma folha de sprites ou colagem.

Criar sprites de Cama, mantendo exatamente a identidade e o tamanho aparente das referências. A captura fixa contexto e a folha de móveis fixa material/forma; não exportar seu fundo nem HUD. Sequência: aproximar parado; sentar na borda; inclinar; deitar; repouso; levantar em ordem inversa. Manter roupa e cama da referência. Separar corpo do personagem e camadas do móvel para oclusão. Não animar a cama deslizando.

Produzir primeiro uma direção compatível com o objeto no cenário, SE, para validar encaixe. Exportar cada estado em PNG RGBA com fundo realmente transparente, contorno limpo sem halo, câmera e escala constantes, sem chão pintado ou sombra de fundo. Não entregar colagem com títulos nem perspectiva variando por quadro. Depois da primeira direção aprovada, produzir as direções necessárias para cada âncora do cenário; não espelhar texto, mochila ou assimetrias. Para transições suaves usar 6 quadros de entrada e 6 de saída, com um quadro de repouso; a duração será controlada pelo motor. Não usar interpolação que deforme mãos.

## Entrega

Guardar os PNG em saida, nomeando por exemplo `01_deitar_SE_enter_00.png` a `_05.png`, `01_deitar_SE_idle_00.png`, `01_deitar_SE_exit_00.png` a `_05.png`. Para objeto separado usar prefixo object; para corpo usar caio. Não colar corpo no móvel. Manter canvas constante e registrar em JSON o tamanho, direção, ordem e ponto de apoio em pixels. A escala final e a âncora de assento/cama precisam ser medidas na integração; não presumir que o pé continua sendo a âncora da pose deitada. Referência de pé: pose_SE_idle.png.

Não substituir as imagens de assets. Rig/sprites ainda precisam de revisão de alinhamento e colisão no jogo.
