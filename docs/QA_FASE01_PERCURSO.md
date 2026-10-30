# QA — percurso real da Fase 01

## Escopo

O teste `test/full_phase_player_test.dart` inicia uma campanha com `GameSession.startNew()` e `finishOpening()`. Usa apenas ações públicas de sessão e `WorldModel.moveTo()` para conduzir Caio; não atribui posição, andar, vida, itens ou eventos e não restaura um save preparado. O ônibus e as escadas mantêm suas transições autoradas de produção.

O percurso verifica: celular pelo HUD; cama antecipada sem conclusão; sofá, cadeira, notebook, guarda-roupa e geladeira com os respectivos estados observáveis; chave e adaptador; porta 203; ajuda a Inês; escadas do 2º ao 1º andar e térreo; entrada residencial; entrega a Orlando; notícia completa; tomada; atadura autorizada no sedã; encontro iniciado pela caminhada ao beco; alavanca; ônibus; pulso; mensagem de Helena; retorno à entrada, escadas, apartamento e cama; persistência da conclusão.

Cada deslocamento de caminhada usa ticks de 1/60 s. Cada tick confirma ausência de sobreposição com a geometria e os outros atores e continuidade do deslocamento no mesmo andar. Aproximações confirmam o POI realmente selecionado por `nearby` antes de `interact()`: o teste não chama diretamente a interação de um objeto distante. Há limites de quadros com mensagens que indicam destino, posição e POI selecionado em caso de travamento.

## Evidências de execução

O agente principal executou o teste focado com diagnóstico: `docs/qa05-percurso.log` termina em `+1: All tests passed!`. O último destino (cama, após retorno completo) foi registrado aos 758 ms do corpo do teste. Esse resultado confirma o percurso de sessão/modelo, sem aprovação visual.

Depois da ação da geladeira passar a ter duração, a suíte completa foi executada novamente em 29/10/2026: **51 testes passaram**, incluindo o percurso de Fase 01 e a regressão de placas duplicadas nas portas. A versão web também foi reconstruída para a inspeção manual.

### Partida manual no navegador

Em 29/10/2026, a campanha foi iniciada pelo menu e jogada no navegador até `FASE 01 CONCLUÍDA`, sem editar posição, inventário ou progresso. Foram usados movimento pelo mapa, aproximação e interação. A sequência observada cobriu abertura, mensagem no celular, coleta de chave/adaptador, porta 203, conversa com Inês, escada do segundo andar ao térreo, saída do prédio, conversa/entrega a Orlando, boletim com legenda, deslocamento ao beco, ferimento, objetivos restantes e retorno ao apartamento. A conclusão e o marco de 02:00 desbloqueado apareceram na tela; `Continuar` no menu mostrou o resumo salvo 5/5.

Observações da partida:

- Andar e corrida mudaram os estados de HUD; após parar com pouco fôlego, a recuperação foi visível e chegou a 100. O ferimento também atualizou o HUD e a corrida ficou indisponível durante a recuperação.
- A transição do apartamento para o corredor e o trajeto das escadas/prédio para a rua funcionaram. O diálogo próximo exibiu `LEITURA LABIAL`; respostas de Caio usaram gesto ou celular. O boletim foi apresentado com `LEGENDA DO BOLETIM`.
- Em horário noturno, foram vistos brilho quente de poste e morcego voando. Essa inspeção confirma pelo menos uma mudança de ambiente dia/noite no navegador, mas não verifica todas as espécies e condições de infectados.
- Foi possível sentar na cadeira, porém o painel de interação cobriu parte do avatar: a pose e a leitura visual da animação não puderam ser avaliadas com confiança nessa tela.
- A arte de piso e rua ainda parece plana/repetitiva em algumas áreas, e objetos do apartamento aparecem juntos no corte isométrico. É uma pendência de composição/oclusão e acabamento, não uma falha do percurso lógico.
- O nome flutuante repetido das portas 203/entrada foi corrigido no renderer; as placas físicas ficam responsáveis por identificá-las. A regra passou no teste e foi confirmada visualmente em uma sessão isolada após o rebuild: a porta mostra a placa `203`, sem um segundo nome sobreposto.

Esta partida foi feita na build web, não em aparelho Android. O jogo inteiro foi concluído. `flutter analyze --no-pub` não reportou erros de análise, mas terminou com código 1 por 22 avisos de estilo `info` (chaves em if/for e dois imports desnecessários); ficam registrados em `docs/qa05-analyze-final.log`. Testes físicos de toque, desempenho, som, proporção em telas reais e aparência final dos sprites continuam pendentes.

Para localizar um trajeto lento no teste focado, executar com `--dart-define=FULL_PHASE_TRACE=true`. O diagnóstico imprime tempo real acumulado, início/fim do destino e posição/caminho/ação a cada 600 quadros. A instrumentação não modifica a simulação nem suas asserções.

## Animação: inspeção de integração

`ActorAnimation` deriva a fase do passo da distância percorrida. Os testes existentes conferem alternância de apoios, ausência de passada quando parado, expansão da respiração e assimetria com ferimento. No renderer, Caio usa a detecção de deslocamento real; NPCs usam `npcMotion`; Davi usa deslocamento real do inimigo. As poses domésticas selecionam o atlas próprio e suas âncoras.

O teste de percurso confirma estados de pose (`lie`, `sit`, `typing`, `reach`) e encerramento ao levantar. Não confirma sozinho a aparência dos pixels. Caio usa atlas de quadros completos, não rig que recorta pernas e tronco; escala, orientação, pivô, apoio e transições ainda precisam de inspeção visual. Testes matemáticos de `ActorAnimation` não substituem essa inspeção.

## Limitações explícitas

- Não executa toques, teclado, câmera, acessibilidade, composição gráfica, áudio ou animações em um dispositivo Android.
- Não comprova aparência dos quatro sentidos do rig, sombras, oclusão de móveis ou alinhamento visual das poses.
- Não cobre a alternativa de passagem a pé; escolhe o ônibus e valida seu pulso.
- Não cobre derrota/retry, tratamento do ferimento ou saque repetido neste percurso.
- Não cobre transferências de atadura pelo armário: a visita ocorre antes do saque autorizado; testes de armazenamento existentes possuem outro escopo.
- Não valida continuação de um save Android real nem preservação após reinstalação.
- `finishOpening()` é a conclusão pública da abertura solicitada para este cenário; leitura integral das páginas da abertura tem teste separado.

## Continuação do QA e autoria de assets — 29/10/2026

- O fluxo local `claude-pxl` gerou quatro peças originais de concreto 64×32. Uma falha real de empacotamento Flutter foi capturada no teste de `rootBundle`; o diretório aninhado foi declarado explicitamente no `pubspec.yaml` e agora os quatro PNGs carregam no bundle. Fontes `.px.js` ficam em `tools/art/`; o APK recebe apenas os exports revisados.
- A seleção dos tiles usa hash determinístico das coordenadas. Teste focal confirma estabilidade, distribuição e ausência de faixas horizontais frequentes. Build web de release completou e uma sessão isolada carregou menu e apartamento com os tiles; a captura manual continua sendo web, não Android.
- Corrigido o estado em que manter corrida pressionada parado inclinava o tronco como se Caio ainda corresse. Testes também confirmam que a passada depende da distância enquanto a respiração depende do tempo.
- Corrigido cancelamento de escalada do gato se o suporte marcado ficar indisponível antes da decolagem; ele não inicia uma descida falsa no mesmo nível do chão.
- As mesmas configurações agora abrem pela pausa, retornam à pausa por botão ou Esc, agrupam preferências e preservam escolhas de áudio. Em web 736×736, a lista rolou até o seletor de idioma e o botão de retorno; a campanha manteve estado.
- Verificação final desta continuação: `flutter test --no-pub --reporter expanded` aprovou **57 testes** (`docs/qa09-tests.log`); focados também passaram para ator (5), animais (10) e preferências/pausa (3). `flutter build web --release --no-pub` completou após as mudanças de UI. `flutter analyze --no-pub` teve zero erros e 21 avisos `info` de estilo.
- `flutter analyze --no-pub` reportou **zero erros de análise e 21 avisos `info` de estilo**. O status do comando continua não-zero por esses avisos.

Pendências visuais que permanecem explícitas: verificar junções e pivôs do rig nas oito direções; conferir o corte/oclusão do banheiro; comparar escala/proporções dos assets em tela pequena; validar rotinas e animações dos animais; revisar a Fase 01 em aparelho Android e medir desempenho/touch/áudio. Os tiles corrigem variedade do piso externo, mas não concluem o acabamento do mapa.

## Continuação — defesa e visibilidade residencial, 29/10/2026

- A campanha agora permite pegar um cano de madeira original antes do beco. Ataque exige arma, fôlego, alcance, direção e linha livre; o dano só ocorre no contato. Quatro acertos derrubam Davi sem morte e atualizam a missão. Arma e vida restante persistem no save; save v2 antigo sem `enemy_health` é carregado com 100.
- O HUD só apresenta vida de Davi quando o encontro foi iniciado e ele está próximo; o botão de ataque aparece então se Caio já tiver a arma. A tecla `F` também golpeia no navegador.
- A seleção de interiores agora limita paredes/blocos e mobília à unidade ocupada e o renderer aplica corte de parede a todos os apartamentos residenciais, sem mudar colisores. Isso valida a seleção lógica, não transparência ou aparência de vidro.
- Arte original do item: fonte `tools/art/weapon_club.px.js`, PNG exportado em `assets/images/item_weapon.png`, registrado em `assets/data/phase_assets.json`.
- Verificação daquele estado: percurso automatizado completo da Fase 01 e HUD de combate passaram; suíte completa: **68 testes**. `flutter build web --release --no-pub` passou.
- A inspeção visual pela aba `127.0.0.1:58405` não foi concluída porque a ponte de automação retornou `browser.user is unavailable` e negou a capacidade de visibilidade do Chrome. A aba/save original `58403` não foi tocada. A implementação de janelas descrita abaixo substitui o estado de “não interativas”; veículos continuam sem chave/dano/direção. Atributos da implementação Java do Project Zomboid seguem desconhecidos sem o serviço JEB do REA.

## Fechamento desta continuação — abertura, janelas e validação, 29/10/2026

- A abertura agora apresenta cinco imagens originais correspondentes à sequência do PDF: pedido de pausa no laboratório, sinal vermelho, retirada do eletrodo, registro do Sujeito 07 e corte para Caio diante da janela do apartamento. Mantém os cinco textos, não revela o nome Caio na cena da criança e dura aproximadamente 65 segundos (13 s por quadro), dentro da meta narrativa de 60–90 s. Texto localizado acompanha português/inglês.
- As artes estão em `assets/images/opening_storyboard_v1.png` e `assets/images/opening_subject07_v1.png`; os recortes do storyboard são desenhados por `NarrativeBackdrop` sem alterar os fundos antigos de outras cenas. Testes de layout carregam os assets no bundle em telas retrato e paisagem.
- O PDF descreve a abertura e a Fase 01 nas páginas 9–11; referências de apresentação e escala estão nas páginas 38 e 40–46. A fase segue o percurso já descrito acima, inclusive alternativas de resolução não letal e conclusão no apartamento. `test/full_phase_player_test.dart` percorre do início ao retorno à cama por APIs públicas da sessão, validando aproximação, colisões, ações, transições, missão e save.
- Janelas dos apartamentos 201–203 e 101–103 agora abrem/fecham por interação próxima. Fechadas mantêm colisão; abertas liberam a passagem da unidade ao corredor; não se pode fechá-las sobre Caio. O estado é salvo em `open_windows`; saves v2 antigos assumem todas fechadas. A imagem atual mostra vidro fechado ou abertura escura, não um interior detalhado visto através do vidro.
- QA final desta continuação: `flutter test` aprovou **70 testes**; `flutter analyze --no-pub` terminou com **No issues found**; `flutter build web --release --no-pub` concluiu. A inspeção manual na aba QA confirmou os cinco quadros da abertura e o interior do 203 isolado, sem hall, NPC ou portas dos apartamentos vizinhos. A aba usada foi a isolada `58405`; o save original `58403` não foi tocado. A aparência do vidro/janela aberta e fechada não foi verificada em tela.
- Limites que permanecem: vista real do interior através do vidro, orientação/pivôs dos sprites, toque e desempenho Android ainda precisam de inspeção manual; veículos continuam estáticos, sem chave/dano/direção. A análise Java do Project Zomboid segue sem decompilação porque o serviço JEB/MCP requerido não está disponível; nenhum código ou asset dele foi copiado.

## Menu principal cinematográfico — 29/10/2026

- Escopo limitado ao menu, conforme orientação do jogador: nenhuma alteração no mapa, ciclo dia/noite ou fase foi feita nesta continuação.
- Criadas duas artes originais de apresentação: `assets/images/menu_santa_aurora_v2.png` e `assets/images/menu_caio_foreground_v1.png`. A segunda tem canal alpha; as duas permanecem assets de UI, fora do manifesto de assets da simulação. Nenhum crédito do PxlPerfect/Pixie Haus foi usado.
- O menu em camadas usa chuva, névoa, pulso do sinalizador e respiração sutil de Caio; o painter tem posições determinísticas e respeita movimento reduzido. A animação só roda quando o menu está ativo e com efeitos habilitados.
- Ações conectadas: Continuar mostra local e marcos reais quando existe save e fica visível/desativado sem save; Novo jogo mantém a confirmação de sobrescrita; Configurações abre as opções existentes; Extras contém apenas Jornada e replay da abertura.
- Inspecionado em navegador numa porta local isolada após build; a imagem observada confirmou hierarquia e recorte em paisagem. A aba/save original não foi aberto nem modificado. Testes de widget cobrem 360×800, 768×1024 e 1366×768, inglês e o fluxo de abertura; não substituem uma verificação visual em Android.
- Validação desta versão: suíte completa **82 testes aprovados**, incluindo o percurso automatizado da Fase 01 e retomada de um save pela opção Continuar; build web de release concluída. `flutter analyze --no-pub` não teve erros; reportou um aviso `info` de estilo já existente em `test/world_render_test.dart:59`.
- Créditos externos gastos: **0**. Não foi necessário baixar assets de terceiros.

## Rechecagem visual da abertura e Fase 01 — 29/10/2026

- Em sessão web limpa, iniciei Novo jogo e percorri manualmente os cinco quadros da abertura. As imagens carregaram e acompanharam os textos; o primeiro e o quarto quadro tiveram breve atraso de carregamento da imagem após avançar, sem quebrar a navegação. Avançar do quadro 5 entrou na Fase 01 e mostrou o objetivo inicial, saúde e fôlego.
- O percurso automatizado `test/full_phase_player_test.dart` passou novamente, junto dos testes do menu, da abertura e do layout (`flutter test test/full_phase_player_test.dart test/menu_preferences_layout_test.dart test/menu_main_test.dart --no-pub`).
- Inspeção visual no navegador identificou uma pendência de enquadramento: Caio aparece pequeno e há bastante área do exterior no primeiro quadro jogável. Não ajustei câmera/mapa nesta rodada; a lógica do percurso segue aprovada pelo teste e a causa visual precisa ser isolada antes de mexer no renderer.
- `flutter build web --release --no-pub` concluiu em 189,3 s. Nenhum save preexistente foi carregado ou alterado. Validação Android continua pendente por indisponibilidade do aparelho.

## Quadros provisórios para vídeos da Fase 01 — 29/10/2026

- Foram criadas quatro imagens originais para ocupar os slots de mídia planejados: cidade antes da abertura, pulso, mensagem de Helena e retorno à cama. Cada PNG fica em `assets/images/video_placeholder_...png` e também em `prompt/video/<cena>/assets/keyframe_placeholder_v01.png`; os prompts e `manifest.json` registram o vínculo e os hashes.
- Novo jogo e replay agora mostram o quadro de Santa Aurora antes das cinco páginas narrativas já existentes. Avançar leva à página 1 sem alterar progresso; Anterior na primeira página volta ao quadro da cidade; Pular continua entrando na fase sem marcar objetivos. Leitura automática avança o quadro após oito segundos.
- Pulso, diálogo da mensagem de Helena e tela de conclusão exibem seus quadros provisórios nos componentes existentes. Texto, diálogo e estado da missão permanecem no motor. Os PNG são stills, não animações nem vídeos; a reprodução de MP4 ainda não está integrada e será necessária quando os arquivos forem entregues.
- Verificação focal: `test/presentation_flow_test.dart` e `test/menu_preferences_layout_test.dart` passaram, incluindo pré-abertura em retrato e paisagem. `python tools/prepare_video_pack.py` e `python tools/verify_media_pack.py` validaram os quatro pacotes e seus hashes. Android e desempenho de vídeo não foram testados; o aparelho está indisponível.

## Apartamento 203: revisão de composição — 29/10/2026

- A captura do renderer revelou que paredes do corredor e pisos/ambientes inferiores continuavam aparecendo quando Caio estava dentro do apartamento. A cena agora limita o piso, paredes e blocos residenciais ao interior ocupado e oculta o patamar externo; isso mantém os colisores ativos. O teste verifica pixels do apartamento vizinho, corredor e parede de divisa para garantir que não vazem para a vista do 203.
- A mobília visível foi verificada quanto a limites dentro do apartamento 203 e interseção entre as áreas ocupadas: sem sobreposição entre os retângulos. A sala ganhou um medalhão no tapete, desenhado em canvas sem textura extra.
- O renderer agora desenha um brilho frio discreto no vidro externo e na janela interior. Testes de imagem confirmam a reflexão no vidro e a presença da janela na parede do andar correto.
- O conjunto de sprites existente já cobre cama, guarda-roupa, escrivaninha/cadeira, cozinha, estante e sofá; não foi adicionado outro bitmap nesta revisão. Banheiro e objetos menores continuam vetoriais no renderer.
- A captura revisada está em `tools/art/out/world-review/apartment-current.png`. Testes automatizados e renderização não substituem a conferência de escala em aparelho Android; esse ponto segue pendente.

## Correção da composição do apartamento 203 — 29/10/2026

- Corrigi a ordem de profundidade das paredes estruturais para que a parede de fundo não passe visualmente sobre a cama. A colisão continua separada da visibilidade.
- Ao focar o apartamento, a base mostra apenas um pavimento de fachada abaixo da unidade; removi o grande volume de dois pavimentos e limitei o patamar externo à área em frente à porta 203. O corredor e apartamentos vizinhos continuam ocultos.
- A porta de entrada e a do banheiro acompanham o corte das paredes no modo interior, em vez de manter folhas com altura de parede inteira.
- Substituí as formas provisórias de vaso, pia e box por sprites transparentes próprios do projeto; o atlas editável e o recortador estão em `tools/art/source/bathroom_fixtures/fixtures.png` e `tools/split_bathroom_atlas.py`.
- Captura atualizada: `tools/art/out/world-review/apartment-current.png`. O teste de renderização cobre o apoio visual da fachada, o patamar, a parede divisória, o tapete e o apartamento vizinho. Suíte completa desta rodada: **95 testes aprovados**. A inspeção de pixels é desktop/web; Android ainda precisa de conferência manual.

## Hall do segundo andar — portas, elevador e escada — 29/10/2026

- No modo corredor, o renderizador desenha apenas o piso compartilhado; itens dos apartamentos ficam ocultos. Unidades fechadas recebem uma cobertura simples e opaca, evitando mostrar o piso externo através delas.
- Portas e paredes do hall têm alturas alinhadas; a numeração usa placas pequenas presas às folhas. O elevador usa o ponto de interação como âncora, com duas folhas, sombra de contato e placa de manutenção. O quadro de avisos foi montado na parede.
- Abri vãos na grade do patamar onde os lances de escada chegam e desenhei corrimãos nos dois lados. A captura `tools/art/out/world-review/corridor-current.png` foi inspecionada no desktop.
- Dona Inês é a vizinha do 202 e participa da ajuda opcional da Fase 01 (sacola rasgada no hall), conforme `docs/FASE_01_PLANO.md`; ela não é um spawn aleatório. Pontos interativos dentro dos apartamentos ficam ocultos enquanto Caio está no corredor.
- Testes focais: `test/residential_world_test.dart` e `test/world_render_test.dart`. A suíte completa passou com **95 testes**; `flutter analyze --no-pub` concluiu com **No issues found**. Teste Android continua pendente.

## Revisão de parede e controles mobile — 29/10/2026

- Paredes de fundo do apartamento agora são renderizadas antes dos móveis; paredes próximas continuam na camada frontal. Isso evita que uma ordem cíclica de profundidade pinte a parede por cima da cama. Colisores permanecem independentes.
- O HUD limita a caixa principal a 360 px em telas menores e 390 px em paisagem; o objetivo ocupa uma linha compacta. Foi removido o rótulo permanente “Caminhando/Correndo”; a ação de corrida permanece como ícone com descrição acessível.
- Pausa e HUD foram compactados sem remover saúde, fôlego, objetivo, progresso, áudio, acessibilidade e navegação. A pausa inclui “Editar controles”.
- O editor permite arrastar joystick, ações e corrida. Posições são normalizadas e salvas em preferências do aparelho, separadas do progresso da campanha; há ação para restaurar o layout padrão. Ainda é necessária conferência tátil em Android.
- Testes focais de layout, persistência do layout e pausa; o teste de renderização do apartamento salva `tools/art/out/world-review/apartment-current.png` para inspeção visual.


## Regressão final desta sessão — 29/10/2026

- A suíte atual completa aprovou **118 testes** (`flutter test --no-pub --reporter compact`); `flutter analyze --no-pub` terminou com `No issues found!`; `flutter build web --release --no-pub --no-wasm-dry-run` concluiu.
- O percurso automatizado da Fase 01 confirma o ciclo do ônibus: Caio precisa chegar à parada, esperar 2,88 s simulados pela chegada, e só então embarcar. A interação direta não permite atravessar a pé antes do evento. O teste segue o arco já escrito no PDF: viagem/pulso, mensagem, retorno ao apartamento e conclusão na cama.
- A geometria de travessia do muro foi corrigida para exigir pontos caminháveis de partida e pouso; o gato agora nasce no acesso válido do muro, evitando bloquear Caio antes do salto.
- Sentar não abre painel de objeto; o mesmo botão passa a “Levantar”. Uma sessão web nova foi aberta em origem isolada e conferida visualmente: o rótulo flutuante “CADEIRA” não aparece sentado e o botão retorna a “Sentar” ao levantar. Esta verificação visual é da build web, não de Android. A qualidade anatômica/orientação da pose continua dependente do atlas atual e precisa de arte/QA adicional.
- Nenhum save das abas originais foi aberto ou alterado. A sessão visual desta rodada usou armazenamento isolado.

### Pendências para não confundir aprovação lógica com “100% pronto”

- A rua e partes externas ainda estão visualmente vazias/repetitivas; não foi feita nesta rodada uma passagem completa de decoração, postes, barricadas militares pré-surto e escombros pós-surto.
- Não há QA em aparelho Android nem validação de toque, desempenho, proporção real, áudio ou vibração.
- A pose de sofá/cadeira, animações de ataque/descanso e encaixe de portas/escadas precisam de uma inspeção visual de todas as orientações e resoluções.
- O ônibus agora chega e o embarque é obrigatório, mas a fase continua pelo pulso, retorno e cama conforme o PDF; embarcar não marca sozinho a conclusão narrativa. Essa diferença entre o pedido de “concluir a fase no ônibus” e a história canônica permanece aberta.
- Não foi possível decompilar o bytecode Java de Project Zomboid: o serviço JEB/MCP não está disponível. Nenhum código ou asset de PZ/mod foi copiado; fontes Lua legíveis foram apenas inventariadas nos relatórios REA existentes.
- Carros dirigíveis com chaves, dano/capotamento por estado do surto, animação completa de animais/NPCs, sistema de janelas/cortinas/vidro e produção 3D em Blender/Unity não foram completados nesta sessão.

## Queda e derrota — 29/10/2026

- Reproduzi a cena com Davi derrotado. A causa do personagem vivo e do corpo simultâneo era `_allPeople`: depois de `resolved`, o renderer ainda recebia Davi como NPC, enquanto desenhava o corpo salvo do encontro.
- Corrigi a regra de presença: Davi continua no cenário se escapar sem ser derrotado; se `enemy_defeated` estiver registrado, só o corpo no ponto salvo é renderizado. Bruno segue a mesma regra após `chapter2_enemy_down`; ele só aparece vivo antes da derrota.
- O corpo permanece salvo na posição do encontro e não bloqueia a navegação. A captura visual atualizada está em `tools/art/out/world-review/fallen-enemy-current.png`.
- Quando a saúde de Caio chega a zero, ele já muda para a pose deitado e a sessão oferece retomada do último checkpoint. A captura dessa tela está em `tools/art/out/world-review/player-defeated-current.png`. Por ser uma história de campanha, a retomada não é morte permanente; o corpo de Caio não fica no mundo após reiniciar do checkpoint.
- A referência do Project Zomboid continua limitada às fontes Lua/XML locais e ao inventário REA descrito em `docs/REA_PZ_MECHANICS_06.md`; não foi copiado código nem asset comercial.

## REA/APKs e smoke test Android — 29/10/2026

- O inventário estático autorizado dos quatro APKs e seus limites está em `docs/REFERENCIA_APKS_REA_2026-10-29.md`. JADX 0.7.1 foi validado e executado pelo REA; isso não executou os APKs nem decodificou gameplay de Unity/IL2CPP, bibliotecas nativas ou `.pak`.
- Acrescentei bloqueio explícito de input do mundo enquanto uma tela modal está aberta. Teste de regressão: fechar a mensagem do celular retorna a `playing`; não mantém o diálogo aberto. Suíte completa: **133 testes**. `flutter analyze`: sem problemas.
- Build debug `0.5.3` / código 10 foi instalado no Samsung A15 apenas como `dev.silencio.silencio.qa2`. A inspeção manual no aparelho cobriu menu, retomada da cena salva, abrir/avançar/fechar a mensagem. O percurso inteiro da Fase 01 não foi jogado fisicamente.
- O arquivo de preferências do QA2 foi restaurado do backup temporário e o SHA-256 conferiu: `9f34d19485d298d875093a20d7fd89e11b7dea36dd48529e6327d1bfda07e02c`. Produção `dev.silencio.silencio` permaneceu intocada.
- Capturas finais temporárias: `C:\Users\giovane\AppData\Local\Temp\silencio-mobile-qa\final-qa.png` (menu) e `final-game.png` (mundo). O save restaurado não foi reiniciado.

## Aceitação da V3 da Fase 01 — 30/10/2026

- Esta seção substitui as notas históricas acima sobre a condição de conclusão: na V3, a Fase 01 termina ao embarcar no ônibus da linha 203 após o pulso, a chegada do ônibus e a mensagem principal. Voltar para a cama já não conclui a fase.
- O ônibus não pode ser embarcado antes dos pré-requisitos. A transição após embarcar grava os eventos de chegada/embarque/conclusão, salva a campanha e abre a tela de conclusão no ponto de ônibus.
- Bia permanece no abrigo como personagem opcional; depois do pulso, Caio pode ler e responder à mensagem dela pelo celular. A resposta entra no diário e no save. Nando só aparece como motorista junto ao ônibus depois de sua chegada, em vez de vagar pela rua.
- A interface usa seis marcos para refletir a sequência V3. As identificações internas legadas de Celina/Inês e Nando/Nestor foram preservadas para compatibilidade com saves existentes.
- A rota automatizada percorre a missão até embarcar e conclui a fase; testes também cobrem tentativa prematura de embarque, descanso na cama sem conclusão e conversa opcional com Bia.
- Verificação final: `flutter test --no-pub --reporter expanded` — 144 testes passaram; `flutter analyze --no-pub` — sem problemas; `flutter build web --release --no-pub --no-wasm-dry-run` — build concluída; `git diff --check` — sem erros de whitespace.
- Limite desta aceitação: os testes automatizados verificam estado, progressão, posição e renderização. Esta rodada não substitui uma inspeção manual completa em Android nem confirma a composição visual em aparelho físico.
