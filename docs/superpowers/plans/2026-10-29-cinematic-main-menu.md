# Menu principal cinematográfico Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Atualizar o menu principal do SILÊNCIO com arte cinematográfica em camadas, animações leves, ações conectadas ao jogo e layout para formatos desktop e mobile.

**Architecture:** Manter `GameShell` como dono dos fluxos de menu e save. Adicionar um painter de atmosfera que só anima com o menu visível, manter as novas artes como assets de apresentação e reutilizar as ações existentes de jornada, abertura, configurações e campanha.

**Tech Stack:** Flutter, Flame existente, CustomPainter e assets PNG.

**Spec:** `docs/superpowers/specs/2026-10-29-cinematic-menu-design.md`

## Global Constraints

- Preservar saves, história e funcionalidades atuais.
- Caio não fala vocalmente; não inventar Libras.
- Não adicionar dependências de runtime ou copiar assets de outro jogo.
- Manter acesso de teclado/toque, idioma, contraste e movimento reduzido.
- Fazer QA em save isolado; não substituir save original.

## Review Focus

- Sem save: Continuar continua visível, desabilitado e sem callback.
- Save existente: Continua mostra local/marcos reais e carrega o estado.
- Retrato estreito: textos e ações rolam ou refluem sem overflow.
- Animação reduzida/menu oculto: efeitos param ou ficam estáticos.
- Extras: somente jornada e replay já implementados são acionáveis.

---

### Task 1: Arte e atmosfera

**Files:**
- Create: `assets/images/menu_santa_aurora_v2.png`
- Create: `assets/images/menu_caio_foreground_v1.png`
- Create: `lib/ui/menu_atmosphere.dart`
- Test: `test/menu_atmosphere_test.dart`

- [x] Copiar as artes revisadas ao projeto e validar alpha no recorte do Caio.
- [x] Criar painter determinístico e leve para chuva, faixas de neblina e pulso da torre; respeitar redução de efeitos.
- [x] Testar renderização em canvas vazio, movimento reduzido e repintura ao animar.

### Task 2: Menu funcional e responsivo

**Files:**
- Modify: `lib/ui/game_shell.dart`
- Test: `test/menu_preferences_layout_test.dart`

- [x] Trocar o backdrop do menu para a nova paisagem e adicionar Caio com respiração sutil.
- [x] Reorganizar Continuar/Novo jogo/Opções/Extras; Continuar desabilitado sem save.
- [x] Criar Extras com Jornada e replay existentes, sem itens vazios.
- [x] Incluir cartão ambiental e três descrições do jogo; esconder/refluir apenas conteúdos não essenciais em retrato pequeno.
- [x] Testar menu em 360×800, 768×1024 e 1366×768, com e sem save e nos dois idiomas.

### Task 3: Revisão final

**Files:**
- Update: `docs/QA_FASE01_PERCURSO.md`

- [x] Executar `flutter test`, `flutter analyze --no-pub` e `flutter build web --release --no-pub`.
- [x] Inspecionar visualmente menu em build web isolada; nenhum save foi alterado.
- [x] Documentar desempenho esperado, testes e limitações do menu.
