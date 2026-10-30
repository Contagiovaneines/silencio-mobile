# Referência Project Zomboid e comunicação de Caio — revisão 0.5

Data: 28/10/2026. Investigação estática e somente leitura da instalação selecionada pelo usuário: `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`. Nenhum executável do jogo foi iniciado, arquivo instalado modificado ou asset comercial transplantado para o SILÊNCIO. Este documento é referência para a implementação original; não é um relatório de partida do Zomboid ou do SILÊNCIO.

## REA: execução e proveniência

O catálogo MCP desta conversa não apresentou ferramentas REA. O launcher `npx` presente no PATH falhou por procurar Node 24.18.0 indisponível. Não foi executado setup nem alterada configuração global. A recuperação utilizou o Node já fornecido pelo ambiente e o pacote REA 6.5.0 já existente no cache npm:

- Node: `C:/Users/giovane/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe`.
- CLI: `C:/Users/giovane/AppData/Local/npm-cache/_npx/af752b90495482d7/node_modules/rea-agents/scripts/rea.mjs`.
- Operação efetiva: `inspect-artifact` no `projectzomboid.jar`, formato JSON completo. Não houve extração ou decompilação.

Foi feita também uma consulta ao catálogo de provedores e à operação REA de unidades JEB. `rea providers` reportou Ghidra sem `GHIDRA_INSTALL_DIR`, Hopper não suportado nesta configuração Windows e IDA não configurado. `rea list-jeb-units --format json` respondeu `capability_unavailable`: precisa de um cliente JEB atendendo no MCP (padrão `http://127.0.0.1:8425/mcp` ou `REA_JEB_MCP_URL`), e a conexão local falhou. Portanto, **não foi possível decompilar o bytecode Java neste ambiente**. Não foi instalado nem configurado um decompilador. O inventário ZIP do JAR e a inspeção de fontes Lua/XML continuam sendo a evidência realmente disponível.

Evidência REA principal: `ev_02d2cd9bcca76d580703a46a28c9269188f11aa3dc682666809784e0e277e2d6`.

Subetapa de inventário: `ev_1e795ac2817dc84f6c1c346bd5c597b1366c608d954a167c6c26cb65cd62822e`.

SHA-256 do JAR examinado: `e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`. Tamanho: 65.682.033 bytes. O provedor `rea-artifact-graph` reconheceu ZIP e registrou 26.098 nós, 26.141 ocorrências e 26.140 arestas. A cobertura declarada é completa para o inventário do diretório central ZIP; isso **não** significa análise completa do comportamento Java.

O JSON canônico completo está em `docs/rea-projectzomboid-artifact.json` (~30 MB, metadados de investigação, fora dos assets do aplicativo). O REA não executou o alvo e ressalva que o inventário não cobre bytes externos às entradas ZIP. A versão comercial exata não foi determinada; o hash identifica a cópia analisada.

Os achados comportamentais abaixo vêm da leitura direta dos textos Lua/XML distribuídos com o jogo, e não de pseudocódigo REA. As seis fontes principais têm tamanho e SHA-256 registrados em `REFERENCIA_ZOMBOID_FONTES_05.json`. Essa distinção evita atribuir ao REA conclusões que o inventário sozinho não estabelece.

## O que os arquivos distribuídos mostram

| Questão | Observação estática | Consequência de projeto proposta para SILÊNCIO |
|---|---|---|
| Sentar em móvel | `media/lua/shared/TimedActions/ISRestAction.lua` calcula direção e lado de aproximação, pede uma posição adjacente válida ao gerenciador de assentos, verifica ocupação e separa a direção anterior e durante o assento | Cada móvel precisa de âncora, aproximação livre, orientação e saída. Não basta deslocar um sprite para o centro do sofá |
| Sentar no chão | `ISSitOnGround.lua` emite um evento e acompanha se o estado sentado começou; levantar usa outro estado/evento | Entrada, repouso e saída devem ser estados explícitos e interrompíveis, não uma pose presa permanentemente |
| Descansar | `ISRestAction.lua` mantém estado de repouso e consulta endurance; o fluxo com animações permite recuperar endurance passivamente enquanto outras ações compatíveis existem | Fôlego e saúde são recursos diferentes; respirar/descansar pode restaurar fôlego sem curar ferimento |
| Beber | `ISDrinkFromBottle.lua` verifica recipiente/inventário, inicia animação com objeto na mão, tem duração, interrupção e consumo na conclusão | Ação original curta com aproximação, alcance, beber e retorno. Só consumir recurso uma vez no contato/conclusão; correr pode interromper |
| Ficar ofegante | `media/AnimSets/player/idle/Idle.xml` referencia um idle normal e um de respiração forte, combinados por um parâmetro chamado `IdleSpeed` | Estado próprio de recuperação visual; não trocar repetidamente entre idle/corrida a cada ponto de stamina |
| Ferimento e passada | `media/AnimSets/player/run/defaultRun.xml` combina `WalkInjury` e `WalkSpeed` e referencia marcha/corrida normais, mancar leve à esquerda/direita e mancar forte | Separar velocidade física de fase de animação; usar marcha assimétrica quando ferido, sem simplesmente acelerar o mesmo corpo rígido |
| Contato dos pés | O mesmo XML declara dois eventos de passo, nas posições normalizadas 0,20 e 0,65 do ciclo | Validar visualmente dois apoios por ciclo; quadros precisam alternar de fato a perna de apoio. Caminhar contra parede não avança a passada |
| Empurrão | `media/AnimSets/player/shove/ShoveDefault.xml` é não cíclico, tem evento de verificação de colisão e períodos de bloqueio/liberação de movimento | Manter antecipação, contato e recuperação. Dano/empurrão só ocorre uma vez, com alcance, direção e obstáculo verificados naquele instante |

Nomes de variáveis/clipes são observações do material distribuído. Não foram copiados clipes, modelos, texturas, sons ou implementações para a campanha. O código Java que calcula os parâmetros e a aparência em execução não foi decompilado ou validado; não é possível deduzir todos os limiares reais apenas dos XML.

## Adaptação original leve para o mobile

As recomendações seguintes são decisões para o SILÊNCIO, não medições de desempenho do Zomboid:

1. Fase de passada ligada à distância realmente percorrida. Caminhada e corrida têm comprimentos de passada próprios; quadros alternam contato esquerdo/direito, passagem e elevação. Não escolher frames só pelo relógio global.
2. Registrar deslocamento e direção por NPC; um personagem móvel não pode continuar sendo renderizado pela imagem parada ou pelo contador de passos de Caio.
3. Estado de recuperação com histerese: entrar quando esgotado, conservar a respiração ao parar até recuperar o fôlego. Não associar automaticamente saúde baixa a falta de ar.
4. Ferimento grave muda limite de velocidade, postura, cadência e recuperação do empurrão. Não retirar todo o controle nem criar uma situação impossível de escapar. Saúde só volta por mecânicas válidas.
5. Animais precisam de estado e posição do chão separados da altura de apresentação. Um gato elevado só pode subir em um suporte marcado e acessível; não atravessa um carro por alterar o Y da imagem. Repouso e marcação do cão são estados, sem spawn repetido de efeitos.
6. Usar sprites originais em atlas, atualização reduzida para agentes distantes e consulta espacial por região. Não importar a arquitetura de animação óssea/arquivos 3D do Zomboid para um aparelho mobile apenas porque funciona no PC.

## Comunicação de Caio — auditoria anterior às correções do lote

O usuário confirmou que Caio é surdo. Isso não autoriza equiparar surdez a ausência de fala em todas as pessoas; para **este personagem**, o projeto já estabelece comunicação sem fala vocal. O parser de `DialogueLine` admite celular, escrita, gesto e Libras para suas mensagens.

Achados na versão anterior à integração deste lote:

- `assets/data/chapter_01.json`: início por mensagem e resposta por celular é coerente.
- `game_session.dart`: Inês, Orlando e Nestor usam o modo genérico `fala`; o texto não explica como Caio recebe a informação nem orienta o interlocutor visualmente.
- `pulse_mother` e `pulse_orlando`: são apresentados como fala mesmo quando esses NPCs podem estar longe de Caio. Distância e posição não sustentam leitura labial. Recomendada a substituição por observações visuais, mantendo o evento narrativo.
- Notícia/televisão tem texto legível no painel, mas precisa deixar claro que é legenda, manchete ou texto exibido; não supor que Caio ouviu a transmissão.
- `ines_caio` é um gesto de oferecer a sacola. Pode continuar como gesto contextual, mas não deve ser renomeado como Libras sem uma animação linguística validada.
- Mensagens de Helena e anotação sobre a tomada já têm meios acessíveis: celular e escrita.

Contrato proposto: toda linha registra meio de comunicação recebido por Caio. Conversa presencial inicia apenas em distância válida, com ambos orientados para o contato; leitura labial exige rosto visível e iluminação suficiente. Quando isso não puder ser representado, usar escrita/celular ou uma observação do que Caio realmente vê. Não transcrever conversas distantes ou fora de quadro como conhecimento dele. O jogo pode manter texto acessível para o jogador sem alegar que a percepção labial é perfeita.

Pistas e perigo precisam de alternativa visual; áudio de ambiente pode ser opção de apresentação ao jogador, mas não o único caminho para completar objetivos. O estado de cansaço também deve ser visível, sem depender de ouvir a respiração.

## As imagens de Libras enviadas

As figuras incluem alfabeto manual, números e sinais isolados de diferentes fontes. Elas são referência visual, não validação de uma frase animada. Soletrar uma frase inteira letra a letra não reproduz automaticamente sua gramática em Libras. Também não se deve presumir que todos os vizinhos saibam sinalizar.

Fontes primárias consultadas:

- [UFSC — expressões não manuais](https://www.libras.ufsc.br/colecaoLetrasLibras/eixoFormacaoBasica/foneticaEFonologia/scos/cap15009/11.html): rosto, olhos, cabeça e tronco têm papéis sintáticos e lexicais. Isso sustenta a necessidade de animar mais que mãos isoladas.
- [INES — curso de Libras](https://www.gov.br/ines/pt-br/assuntos/libras/sobre-o-curso-de-libras) e [Manuário do INES](https://manuario.ines.gov.br/): referências para produção e revisão por pessoas qualificadas. A página específica do alfabeto apresentou barreira de verificação nesta consulta; não foi contornada e não serve como validação de cada desenho enviado.

Para Libras no jogo, preparar um contrato por fala: glosa/expressão pretendida, contexto, referência de movimento, enquadramento com rosto e mãos legíveis, revisão por pessoa fluente/profissional e status de validação. Até haver esse material, usar os modos de escrita/celular já funcionais e gestos contextuais explicitamente identificados. Não apresentar uma animação gerada apenas a partir dessas figuras como tradução certificada.

## Cobertura e pendências

- REA: inventário autenticado do JAR concluído; tentativa de listar unidades JEB documentou ausência do backend local. Sem decompilação Java ou execução do Project Zomboid.
- Comportamentos: leitura estática de seis fontes distribuídas; aparência real do Zomboid, custos de CPU/GPU e todos os limiares permanecem não verificados.
- Comunicação: auditoria do estado anterior ao lote e contratos propostos; o agente de integração está aplicando as mudanças, portanto conferir o código e o QA final antes de afirmar que todas foram concluídas.
- Assets: nenhum material comercial ou figura de Libras foi incorporado como sprite final.

Atualização de perguntas sobre casas, containers, portas/janelas, armas, veículos, spawns e animais está em [REA_PZ_MECHANICS_06.md](REA_PZ_MECHANICS_06.md). Essa leitura amplia a inspeção de Lua/XML, mas não altera a limitação de decompilação Java: JEB/MCP continua sem serviço ativo; os detalhes do engine seguem desconhecidos.
