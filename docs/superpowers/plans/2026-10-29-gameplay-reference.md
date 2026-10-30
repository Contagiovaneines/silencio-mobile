# Jogabilidade por referência

Pedido: aproximar o SILÊNCIO da jogabilidade de Project Zomboid. Manter implementação e arte próprias, história e saves existentes.

Referência examinada: fontes Lua locais de ação/navegação e evidência Java já documentada. Não foi realizada uma partida manual no PZ nesta revisão. Princípios: orientação separada de deslocamento, ação ligada à proximidade e interrupção de navegação por comando manual.

Implementação escolhida: aproveitar WorldModel/Flame atuais. Não portar engine ou inventário completo do jogo de referência.

- [x] Mira independente, deslocamento cauteloso, corrida temporária e saída limpa ao pausar.
- [x] Mouse direito mira, esquerdo golpeia durante a mira; preservar F/E/espaço e controles de toque.
- [x] Clique em objeto visível aproxima e revalida ação no destino; movimento manual cancela a intenção.
- [x] Retículo de direção, sem revelar alvos através de paredes.
- [x] Testes de orientação, interrupção, alcance, percurso, saves e build. Evidências em JOGABILIDADE_REFERENCIA_2026-10-29.md.
