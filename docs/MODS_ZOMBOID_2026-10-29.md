# Mods e referência visual — 29/10/2026

Fonte local: `C:/Users/giovane/Downloads/mods`. Inventário completo dos nove diretórios e 1.431 arquivos, com tamanho e SHA-256 de cada arquivo: `mods-zomboid-inventory-2026-10-29.json`. Inventário não significa leitura integral de cada arquivo. Leitura focada nos manifestos, scripts e configurações abaixo; nenhum mod foi executado ou copiado para os assets/código do jogo.

| Mod | Mudança observada | Aplicação ao SILÊNCIO |
|---|---|---|
| DynamicFacialExpressions | `DynamicFacialExpressions.lua`: expressão sobreposta ao visual; avaliação de estados, prioridades e intervalo mínimo entre mudanças. | Separar visual de estado e preservar identidade do personagem. A animação de Caio agora usa os quadros inteiros; não transplantar overlays 3D. Expressões faciais novas não foram criadas nesta revisão. |
| hydEyes | `hydEyesData.lua`, `hydEyesBloodshot.lua`: camadas de olhos e vermelhidão conforme estado; atualização limitada e só quando a aparência muda. | Alterações visuais por estado, sem alterar lógica física. Não importar roupas/olhos 3D para sprites 2D. |
| GRMT Big Sheet Bag | `mod.info`, `GRMT_BigSheetBag.lua`, `GRMTTakeApartBag.lua`: bolsa colocável, aparência/nome/símbolo separados do conteúdo; desmontagem valida recipiente vazio. | Preservar conteúdo/saves quando mudar arte. Não adicionar capacidade 100 nem receita de lençol sem definir inventário correspondente. |
| GRMT No Random Screams | `GRMT_noscreams_sounds.txt`: substitui eventos de cachorro, grito, coruja e lobo. | Não usar sons aleatórios como percepção obrigatória de Caio. Não remove paredes, telhados ou câmera. |
| GRMT Quick Vehicle Entry | `GRMT_QuickVehicleEntry.lua`: duplo clique escolhe assento, valida porta/tranca, navega até a porta e revalida na chegada. | Interação precisa de percurso físico e validação no destino. A entrada em prédio continua usando portas e colisões existentes. Direção de veículos não foi adicionada. |
| GRMT Strip All Vehicle Parts | `GRMT_StripAllVehicleParts.lua`: fila de remoção de peças com requisitos, chaves, ferramentas e entrega no chão. | Ações sequenciais interrompíveis; não transformar veículos decorativos em sistemas de mecânica sem estado próprio. |
| Kader Solar Station | `mod.info`, `WorldUtilities.lua`, `KSS_LightCircuit.lua`: equipamentos de geração/armazenamento, localização por quadrado e circuitos registrados. | Separar objeto no chão de volume visual e salvar conexões explicitamente. Rede elétrica completa não foi adicionada. |
| PlagueSuit | `mod.info`, `plaguemask.txt`, XML de vestuário: roupas, máscara/filtros e receitas com habilidades. | Referência de equipamento por estado; não copiar modelo, máscara ou estatísticas. Não há mudança de renderer arquitetônico nesses arquivos. |
| TheLastCure | `mod.info`, `LastCure_Autopsy.lua`, `LastCure_Infection.lua`: ação de autópsia, proteção e progressão de infecção com prazo; receitas/cura declaradas no manifesto. | Ações com condições e consequências persistentes. Não introduzir a cura desse mod na história do SILÊNCIO. |

Nenhum dos nove mods examinados fornece o corte de paredes/telhado mostrado nas capturas. Essa referência vem do jogo base. As imagens sustentam: ambiente exterior contínuo; fachada/telhado por fora; corte de cobertura e paredes que ocultam o personagem por dentro; móveis e personagem sobre o mesmo chão. A implementação desta revisão é original.

## REA

Repositório solicitado encontrado em `C:/Users/giovane/Desktop/editor/rea`; lidos `AGENTS.md`, a skill local REA e o guia de recuperação. A árvore de fontes aponta para um runtime compilado; foi reutilizada a CLI 6.5.0 já disponível no cache npm, documentada na investigação anterior. Não alterei instalação, configurações globais ou arquivos do REA/PZ.

Comando efetivo: Node empacotado do Codex + `rea.mjs list-jeb-units --format json`. Resultado: código `capability_unavailable`, categoria `unsupported_provider`, provedor `jeb`, razão `fetch failed`. Requer cliente JEB atendendo em `http://127.0.0.1:8425/mcp` ou endpoint explícito. O JAR não foi decompilado. Inventário anterior do JAR permanece em `REFERENCIA_ZOMBOID_QA_05.md`; não atribuir a ele comportamento do renderer Java.

## Implementação e QA desta revisão

- Removido recorte que isolava o chão do apartamento no vazio.
- Contexto externo desenhado abaixo do andar atual, fachada inferior e laje conectadas; unidades vizinhas fechadas.
- Paredes alinhadas no centro dos colisores; frente baixa ao ocupar apartamento/corredor; rodapés e materiais de reboco.
- Caio usa quadros completos, sem segunda deformação de pernas; sola em y=119 do atlas de 128px alinhada ao chão.
- Passada dos NPCs acompanha a direção projetada no chão; movimento continua ligado à distância real.
- Pisos externos originais gerados com pxl, revisados antes de integrar. Fontes em `tools/art/neighborhood_ground.px.js`, previews fora dos assets.
- Escada descendente recortada ao vão e escada ascendente com volume lateral; navegação e transições existentes preservadas.
- Telhados inclinados e cursos de telhas nos blocos residenciais genéricos; fachadas com materiais e base.
- Janelas do andar ativo sem deslocamento vertical duplicado; teste de pixels reproduziu a janela acima do teto antes da correção e passou depois.
- Capturas reais do Canvas em `tools/art/out/world-review/`: apartamento, corredor, primeiro andar, entrada, exterior e rua. São renderizações offline; não equivalem a teste manual no navegador/aparelho.

Pendências: validação manual Android, revisão artística final pelo usuário, novos ciclos completos em oito direções para NPCs e animação corporal contínua durante a troca de andar. Não afirmar equivalência visual completa com Project Zomboid nem implementação de todas as mecânicas dos mods.

Verificação final: `flutter test --reporter expanded`: 81 testes passaram, incluindo percurso real de apartamento/escadas/rua/retorno e persistência existentes. `flutter analyze --no-pub`: nenhuma ocorrência. `flutter build web --release --no-pub --no-wasm-dry-run`: build/web gerado. Dez PNGs originais verificados em grade 64×32 e transparência; 158 entradas do manifesto sem arquivos ausentes. Logs completos em `tools/art/out/world-review/`. Sem teste manual Android ou de partida no navegador nesta revisão.
