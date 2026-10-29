# Auditoria da apresentação dos atores

## Observações

As sequências originais de caminhada e corrida não contêm arquivos idênticos: a medição de diferença entre quadros está em `QA_ACTOR_SPRITE_AUDIT.json`. A inspeção visual mostra mudanças pequenas na silhueta de apoio das pernas. Portanto, trocar o contador de quadros sozinho não resolve a percepção de rigidez.

Os NPCs eram desenhados com uma imagem única e sem locomoção; Davi também usava uma imagem única com rotação do corpo. As poses domésticas vêm de recortes sem o espaço transparente das imagens em pé, e recebiam uma escala visual maior.

## Alterações

- Rig leve de Canvas sobre as imagens originais, com pernas em oposição, elevação dos pés e oscilação do tronco. A passada usa distância percorrida, não tempo de tecla pressionada: colisão não continua produzindo passos.
- NPCs usam posição, direção e distância reais fornecidas pelo modelo; o interlocutor vira a orientação disponível para Caio durante o diálogo.
- Fôlego em recuperação amplia o movimento do peito e inclina o tronco. Ferimento grave introduz assimetria e usa a pose de dor no tronco; a física permanece sob responsabilidade de WorldModel.
- Poses de sentar, digitar, alcançar e deitar têm escala ajustada ao tamanho visível do personagem em pé.
- Etiquetas de ambientes, NPCs e ruas deixam de ser legendas permanentes. O objeto interativo próximo selecionado exibe o nome; percepção mantém marcadores discretos, sem uma lista simultânea de textos.

## Contratos

O renderer consome `recoveringBreath`, `severelyHurt`, `enemyWalked` e `npcMotion(id)` com `{facing, traveled, moving}`. O estado de recuperação deve permanecer ativo até recompor todo o fôlego. Corrida visual exige corrida efetiva, sem recuperação, sem ferimento grave e com stamina acima de 5.

## Limites e validação

Nenhuma arte original foi sobrescrita e nenhum recurso de Project Zomboid foi copiado. Este rig é uma melhoria provisória de apresentação: não substitui animação desenhada de oito direções, articulação completa dos braços ou Libras linguisticamente validada. Espelhar a orientação disponível de um NPC não cria vistas novas.

Foram adicionados testes de oposição das pernas, imobilidade contra obstáculos e diferença entre respiração normal, fadiga e ferimento. A execução de testes e análise está centralizada no agente principal. Revisão visual em jogo ainda deve verificar as junções dos recortes nas pernas, todas as direções, o apoio no sofá/cadeira, as transições de animação e a leitura em tela pequena.
