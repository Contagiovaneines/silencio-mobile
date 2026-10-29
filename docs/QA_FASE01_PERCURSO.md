# QA — percurso real da Fase 01

## Escopo

O teste `test/full_phase_player_test.dart` inicia uma campanha com `GameSession.startNew()` e `finishOpening()`. Usa apenas ações públicas de sessão e `WorldModel.moveTo()` para conduzir Caio; não atribui posição, andar, vida, itens ou eventos e não restaura um save preparado. O ônibus e as escadas mantêm suas transições autoradas de produção.

O percurso verifica: celular pelo HUD; cama antecipada sem conclusão; sofá, cadeira, notebook, guarda-roupa e geladeira com os respectivos estados observáveis; chave e adaptador; porta 203; ajuda a Inês; escadas do 2º ao 1º andar e térreo; entrada residencial; entrega a Orlando; notícia completa; tomada; atadura autorizada no sedã; encontro iniciado pela caminhada ao beco; alavanca; ônibus; pulso; mensagem de Helena; retorno à entrada, escadas, apartamento e cama; persistência da conclusão.

Cada deslocamento de caminhada usa ticks de 1/60 s. Cada tick confirma ausência de sobreposição com a geometria e os outros atores e continuidade do deslocamento no mesmo andar. Aproximações confirmam o POI realmente selecionado por `nearby` antes de `interact()`: o teste não chama diretamente a interação de um objeto distante. Há limites de quadros com mensagens que indicam destino, posição e POI selecionado em caso de travamento.

## Evidências de execução

O agente principal executou o teste focado com diagnóstico: `docs/qa05-percurso.log` termina em `+1: All tests passed!`. O último destino (cama, após retorno completo) foi registrado aos 758 ms do corpo do teste. Esse resultado confirma o percurso de sessão/modelo, sem aprovação visual.

Depois dessa execução, a ação da geladeira passou a ter duração: o teste foi atualizado para conferir que o painel fecha e `drink` inicia sem consumir a água imediatamente; espera a ação terminar, verifica o consumo e reabre a geladeira para confirmar a indisponibilidade da segunda porção. Essa revisão ainda aguarda nova execução pelo agente principal.

Para localizar um trajeto lento no teste focado, executar com `--dart-define=FULL_PHASE_TRACE=true`. O diagnóstico imprime tempo real acumulado, início/fim do destino e posição/caminho/ação a cada 600 quadros. A instrumentação não modifica a simulação nem suas asserções.

## Animação: inspeção de integração

`ActorAnimation` deriva a fase do passo da distância percorrida. Os testes existentes conferem alternância de apoios, ausência de passada quando parado, expansão da respiração e assimetria com ferimento. No renderer, Caio usa a detecção de deslocamento real; NPCs usam `npcMotion`; Davi usa deslocamento real do inimigo. As poses domésticas selecionam o atlas próprio e suas âncoras.

O teste de percurso confirma estados de pose (`lie`, `sit`, `typing`, `reach`) e encerramento ao levantar. Não confirma aparência dos pixels. O rig corta pernas e tronco em regiões fixas do sprite; proporção, emenda, orientação e pivô precisam de inspeção visual em todas as direções. Testes matemáticos de `ActorAnimation` não substituem essa inspeção.

## Limitações explícitas

- Não executa toques, teclado, câmera, acessibilidade, composição gráfica, áudio ou animações em um dispositivo Android.
- Não comprova aparência dos quatro sentidos do rig, sombras, oclusão de móveis ou alinhamento visual das poses.
- Não cobre a alternativa de passagem a pé; escolhe o ônibus e valida seu pulso.
- Não cobre derrota/retry, tratamento do ferimento ou saque repetido neste percurso.
- Não cobre transferências de atadura pelo armário: a visita ocorre antes do saque autorizado; testes de armazenamento existentes possuem outro escopo.
- Não valida continuação de um save Android real nem preservação após reinstalação.
- `finishOpening()` é a conclusão pública da abertura solicitada para este cenário; leitura integral das páginas da abertura tem teste separado.

