# QA de animação dos atores

## Caio

O renderer principal usa atlas de quadros completos, sem rig de pernas sobre o sprite de Caio. `ActorFrames` recorta células de 128×144; `SilencioGame` desenha cada uma em 80×90 com nearest-neighbor e ancora a sola em `(64,119)`. As linhas do atlas são E, SE, S, SW, W, NW, N e NE. Repouso tem quatro posições; caminhada e corrida têm seis quadros. Locomoção avança conforme a distância percorrida, não apenas pelo tempo de tecla pressionada.

`SpriteFacing` continua dono da seleção de orientação. A projeção e o colisor pertencem ao mundo e permanecem independentes da altura visual do sprite. A entrada por teclado e joystick chama a mesma atualização do `GameSession`/`WorldModel`.

## Revisão visual e correção de corrida

Os atlas de corrida com mochila tinham troca de orientação dentro de algumas linhas. A normalização por quadro foi corrigida em `tools/art/build_actor_sources.py`; `tools/art/actor_skins.px.js` é o derivado de autoria e `assets/images/actors/actor_caio_run.png` é a exportação runtime revisada. Dez células foram espelhadas uma vez para manter a direção constante; as outras 38 células da corrida permaneceram iguais ao runtime anterior.

As poses sem mochila também recebiam uma normalização de altura duplicada, o que fazia a escala variar entre frames. `nobag_locomotion_cells` normaliza os 48 quadros de cada estado diretamente à mesma altura antes do ciclo ser aplicado. Os novos atlas `actor_caio_nobag_walk.png` e `actor_caio_nobag_run.png` mantêm o contrato 768×1152, células 128×144 e pivô de sola em `(64,119)`. `tools/art/test_actor_locomotion_alignment.py` verifica escala e base antes da deformação de passada, sem exigir que os pés fiquem no chão durante quadros intencionalmente aéreos da corrida.

Comparações, folhas de contato e GIFs derivados dos atlas runtime ficam em `tools/art/out/animation-review/`, `tools/art/out/animation-review-candidate/` e `tools/art/out/caio-animation-qa/`. São artefatos de revisão, não carregados pelo jogo.

## Cobertura e limites

O projeto tem testes de atlas/seleção de quadro, ciclo por distância, bloqueio contra obstáculos, stamina, controles e renderização. Nesta rodada passaram `python tools/art/test_actor_locomotion_alignment.py`, `python tools/art/verify_asset_pack.py` (56 atlas, 2.800 células animadas), `flutter analyze`, `flutter test` (134 testes) e `flutter build web --release`. A Fase 01 foi reaberta no navegador em origem de teste separada após a integração. O controle por teclado moveu Caio; `R` + direção iniciou corrida e reduziu o fôlego de 100 para 83. As folhas lado a lado e os ciclos em GIF foram inspecionados visualmente. O arrasto isolado no joystick do navegador não foi confiável, então o toque contínuo ainda precisa ser conferido em dispositivo Android.

Ainda requer revisão: qualidade artística dos sapatos e apoio plantar nas poses de passada, transições entre estados em tela pequena, joystick multitoque e aparelho Android. A inspeção em GIF não substitui confirmar visualmente deslizamento dos pés no jogo em execução.

## Reprodução de QA

Na raiz do projeto:

```powershell
python tools/art/build_caio_animation_qa.py
python tools/art/test_actor_locomotion_alignment.py
flutter analyze
flutter test
flutter build web --release
```

Para inspecionar o jogo no navegador desktop: `flutter run -d chrome` ou `JOGAR_NO_PC.cmd`. A revisão desta sessão usou uma origem web de teste diferente da aba original para não gravar no progresso dela.
