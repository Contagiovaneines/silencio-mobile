# Prédios conectados e defesa da Fase 01 — Plano

> **Execução:** tarefas independentes podem usar agentes; integração final e gate são do agente principal.

**Objetivo:** fazer interiores legíveis por cômodo e dar ao jogador meios claros, justos e persistentes de se defender no encontro da Fase 01.

**Arquitetura:** manter `WorldModel` como fonte de posição, andar, colisão e estado de missão. O renderer escolhe o conjunto visual ativo: fachada opaca do lado de fora; somente o apartamento visitado em vista superior/cutaway quando Caio entra. Interações (porta, janela, armário, arma e inimigo) mudam estado da campanha/mundo através de ações existentes, sem colidir a geometria visual com o registro de progresso.

**Tecnologia:** Flutter/Flame, mapa isométrico 2D e testes Dart existentes.

**Especificação:** pedido atual do usuário; restrições em `AGENTS.md`; fatos e limites de referência em `docs/REFERENCIA_ZOMBOID_QA_05.md`.

## Restrições globais

- Preservar história, saves e interações já existentes.
- Caio se comunica por meios acessíveis; não apresentar gesto aproximado como Libras validada.
- Criar lógica e arte originais; nenhum código ou asset comercial do Project Zomboid entra no jogo.
- Manter colisores e chão independentes da altura/aparência dos sprites.
- Não instalar dependências de runtime ou ferramentas externas no APK.
- REA/JEB só pode afirmar decompilação quando houver serviço/provedor real conectado e evidência devolvida.

## Foco da revisão

1. Apartamentos vizinhos nunca aparecem por dentro quando Caio está em 203; teste de visibilidade por andar/cômodo.
2. Fora do prédio as paredes escondem o interior; vidro/janelas são a única visão autorizada; inspeção web/manual.
3. Porta/janela fechada preserva colisão e aberta não altera indevidamente rotas ou a progressão; teste de transição e colisão.
4. Ataque só causa efeito uma vez quando alcance, direção, fôlego e estado do inimigo são válidos; teste de windup, contato e cooldown.
5. Arma e estado do inimigo persistem sem invalidar saves antigos; teste de serialização/recarga e teste de save v2 anterior.

---

### Tarefa 1: evidência REA e referência Project Zomboid

**Arquivos:** atualizar `docs/REFERENCIA_ZOMBOID_QA_05.md` e acrescentar `docs/REA_PZ_MECHANICS_06.md`.

- [x] Reutilizar inventário e fontes da análise anterior.
- [x] Distinguir o que REA inventariou, o que os arquivos Lua/XML mostram e o que continua desconhecido sem JEB/execução.
- [x] Mapear fontes relevantes a visibilidade de casas, móveis/containers, combate, armas, carros/chaves e animais.
- [x] Não atribuir análise Java ao REA nem copiar implementação/arte.

### Tarefa 2: visibilidade por ambiente

**Arquivos:** `lib/game/silencio_game.dart`, `lib/game/building_layout.dart`, testes de render/layout.

- [x] Criar primeiro um teste que detecte unidade visual ativa e vizinho oculto.
- [ ] Manter fachada externa opaca sem expor móveis/interior; janelas são aberturas visuais controladas. (Fachada segue opaca; a janela atual é desenho de vidro/luz, sem vista real para o interior.)
- [x] No interior, desenhar somente a unidade atual; o corte de paredes agora reconhece qualquer apartamento, preservando colisores.
- [ ] Verificar pixels no navegador em entrada/saída; a ponte de automação rejeitou recarga/acesso à aba. Testes de modelo passaram; Android ainda requer aparelho.

### Tarefa 3: combate justo e arma da Fase 01

**Arquivos:** `lib/models/campaign.dart`, `lib/game/game_session.dart`, `lib/game/world_model.dart`, renderer e testes de combate.

- [x] Fazer o jogador encontrar/pegar arma por aproximação e salvar seu estado sem quebrar saves v2 existentes.
- [x] Implementar windup, contato direcional/rangeado, custo de fôlego e cooldown; inimigo dá oportunidade visual de esquiva.
- [x] Expor saúde do inimigo e derrota/encerramento não letal à missão; renderizar barra somente quando o inimigo está visível/próximo.
- [x] Testar vitória, evasão, dano ao jogador, cooldown, persistência e percurso completo.

### Tarefa 4: interações arquitetônicas e frota (etapa seguinte)

- [ ] Portas abertas/fechadas já existentes: preservar animação e passagem correta.
- [x] Adicionar estado visível e interativo às janelas sem permitir atravessar vidro fechado. Fechada colide; aberta cria passagem; não fecha sobre o jogador; estado persiste e saves v2 antigos abrem fechadas. A vista pelo vidro ainda é apenas vidro/luz, sem interior detalhado.
- [x] Preservar armário/geladeira com aproximação, estado aberto e armazenamento sem duplicar itens.
- [ ] Definir evento narrativo explícito que altera carros estacionados para acidentados; chave e direção exigem uma interação separada e testada.

## Validação final

- [x] `flutter test` (70 testes passaram, incluindo percurso completo da fase e visibilidade por unidade).
- [x] `flutter build web --release --no-pub`.
- [x] Inspeção visual na aba QA confirmou abertura com 5 quadros e apartamento 203 isolado; hall/NPC/portas vizinhas não são desenhados no interior.
- [ ] Revisão visual da janela aberta/fechada e do encontro de luta continua pendente; Android requer aparelho.
- [ ] Inspecionar logs de asset e exceções; registrar separadamente teste web, Android e evidência REA.
