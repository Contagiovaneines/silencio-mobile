# Jogabilidade por referência — SILÊNCIO

Foram comparados os mecanismos locais já investigados de Project Zomboid e as fontes Lua de navegação/ações com os controles atuais do SILÊNCIO. Não foi observada uma partida manual do PZ nesta revisão. Não foram copiados código, sprites, interface, mapa ou clipes do jogo comercial.

Referências: `docs/JAVA_PZ_CFR_2026-10-29.md`, `docs/REA_PZ_MECHANICS_06.md` e `media/lua/client/Vehicles/TimedActions/ISPathFindAction.lua` na instalação local de PZ. Esse Lua mostra navegação com validação de resultado e cancelamento por comando manual; não estabelece a implementação completa do pathfinding Java. A [nota oficial 42.21](https://projectzomboid.com/blog/news/2026/09/42-21-stable-released/) também confirma a preocupação com visibilidade/corte de objetos, já tratada nas revisões anteriores do nosso renderer.

## O que mudou

| Antes | Agora |
|---|---|
| Andar sempre alterava a direção do olhar. | Mirar mantém a orientação enquanto Caio recua ou se desloca lateralmente. |
| Corrida dependia de alternância. | Shift corre enquanto pressionado; R e botão de toque continuam alternando corrida. Mirar impede corrida e reduz a velocidade. |
| Clique no cenário apenas escolhia destino. | Clique num objeto/pessoa visível aproxima e executa a interação ao alcançar distância e acesso válidos. Clique no chão continua sendo movimento. |
| Era preciso tentar interagir novamente após chegar. | A intenção de interação é revalidada no destino; teclado/joystick, mudança de fase e novo destino cancelam a intenção antiga. |
| Golpe sem pose específica de ataque. | Preparação/contato/recuperação usam poses originais existentes; a arma original é desenhada na mão durante mira/golpe. |
| Golpe manual só podia começar apontado para um acerto válido. | Durante a mira, pode haver golpe no vazio, com custo de fôlego e som de erro; nenhum alvo atrás de Caio recebe dano automaticamente. |

O ataque continua exigindo arma, encontro ativo, fôlego e recuperação. O contato continua validando direção, alcance e obstáculo. Não foi adicionado autoaim. O retículo fica avermelhado quando há obstáculo até o ponto mirado; não revela pessoas ocultas.

## Controles

- PC: WASD/setas movem; segurar botão direito mira; pressionar esquerdo com direito segurado golpeia; Shift corre enquanto pressionado.
- E, F, espaço, R e demais atalhos anteriores continuam funcionando.
- Clique/toque num objeto visível: aproximar e interagir. Movimento manual cancela essa aproximação.
- Os controles de toque anteriores permanecem. A mira independente por mouse é uma melhoria de PC; não foi inventada uma animação nova em oito direções para celular.
- Ao pausar ou trocar de tela, a mira e a corrida temporária são limpas. As intenções de clique não entram no save.

## Verificação e limites

Testes de recuo mantendo orientação, bloqueio de corrida durante mira, aproximação física até a chave, cancelamento manual, recusa de interação remota, golpe errado sem dano e limpeza ao pausar. Teste de widget envia eventos reais de botões simultâneos: o segundo botão aparece como mudança de movimento e deve produzir o golpe.

Captura do renderer: `tools/art/out/world-review/combat-aim-current.png`. Não é gravação de partida nem validação de sensação em Android. A campanha, os saves e as mecânicas de fachada/interior anteriores são preservados. O resultado aproxima controles e ações; não é uma cópia completa de Project Zomboid.

Evidência automatizada: suíte completa com 95 testes aprovados em `gameplay-test.log`. Após o ajuste visual da arma e a indicação da corrida temporária, quatro testes específicos de controles/mouse passaram novamente em `gameplay-input-test.log`; a captura de combate passou em `gameplay-aim-render.log`. Análise estática sem ocorrências em `gameplay-analyze.log`. Logs permanecem em `tools/art/out/world-review/`.

Build web release final concluído com retorno zero: `gameplay-build.log`, saída em `build/web`.
