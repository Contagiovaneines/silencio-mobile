# Sprites recebidos — integração na Fase 01

Origem: pasta enviada pelo usuário em `Documents/Codex/2026-10-29/.../outputs/SILENCIO_sprites`.
O `LEIA-ME.txt` do pacote descreve os PNGs como sprites redesenhados por geração a
partir de referências do projeto, com transparência e perspectiva isométrica.

| Arquivo no jogo | Uso | Colisão |
| --- | --- | --- |
| `received/chapter01/street_market_facade.png` | Fachada individual detalhada da mercearia do Orlando; o interior e a entrada continuam sendo sistemas do jogo. | A geometria atual do bloco e da porta controla entrada e colisão. |
| `received/chapter01/bus_shelter.png` | Abrigo físico do ponto de ônibus, alinhado na calçada. | Retângulo dedicado fora da faixa de tráfego e do ponto onde Caio espera. |
| `received/chapter01/street_bus_stop_sign.png` | Placa física com pictograma de ônibus. | Retângulo estreito no meio-fio. |
| `received/chapter01/street_bench.png` | Bancos colocados nas duas calçadas, longe da faixa de tráfego. | Retângulos dedicados. |
| `received/chapter01/street_lamp.png` | Postes de rua; o jogo ainda controla a iluminação dinâmica de dia/noite. | Elementos decorativos fora do caminho principal. |
| `received/chapter01/street_tree.png` | Árvore original feita em PXL para preencher canteiros sem depender de imagem de fundo. | Colisão no tronco, não na copa. |

Os personagens estáticos, o ônibus de uma vista, os carros e as imagens compostas
de cômodos não foram importados: o projeto já possui animações de personagem,
veículos com vistas direcionais e interiores montados com objetos e colisores.
Trocar esses sistemas por imagens estáticas quebraria movimento, escala ou
interação. Os demais itens do pacote ficam disponíveis para integração quando
houver um encaixe claro com uma cena da Fase 01.

Os sprites externos vieram do pacote `SILENCIO_Fases_0-2_sprites`; a árvore foi
desenhada para este projeto em `tools/art/streetscape.px.js`. Tudo está registrado
em `assets/data/phase_assets.json` e incluído pelo `pubspec.yaml`. A faixa de
pedestres é desenhada no chão do mapa. A renderização usa objetos individuais,
mantendo o interior, as colisões, as rotas e a iluminação sob controle do jogo.
