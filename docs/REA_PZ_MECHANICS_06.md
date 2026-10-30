# Project Zomboid: mecanismos úteis para SILÊNCIO (revisão 0.6)

Atualização de 29/10: a decompilação Java focada foi realizada posteriormente com CFR direto, sem serviço JEB. Ver `JAVA_PZ_CFR_2026-10-29.md` para entradas, hashes, achados e limites. O bloqueio JEB abaixo descreve a execução REA anterior e continua válido para esse provedor específico.

Data: 29/10/2026. Alvo informado: `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`. Esta é uma leitura estática, local e somente leitura. Nenhum processo do jogo foi iniciado; nenhum arquivo, código ou asset do PZ foi copiado para o SILÊNCIO.

## Limite da decompilação REA

O inventário REA anterior continua sendo a evidência válida para o JAR. O SHA-256 é `e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`; a evidência REA é `ev_02d2cd9bcca76d580703a46a28c9269188f11aa3dc682666809784e0e277e2d6`. Ela identifica estrutura ZIP e recursos, não o comportamento Java. O pedido anterior para unidades JEB foi bloqueado porque não havia cliente JEB/MCP na porta local padrão; não há ferramenta REA MCP anunciada neste contexto. **O bytecode Java ainda não foi decompilado.** Não repeti a chamada JEB indisponível. O relatório de proveniência completo está em [REFERENCIA_ZOMBOID_QA_05.md](REFERENCIA_ZOMBOID_QA_05.md).

As observações abaixo vêm de fontes Lua/XML distribuídas e dos seus digests, não de pseudocódigo Java nem de uma sessão jogada. Separar isso é essencial: o jogo entrega operações a tipos Java (`IsoWindow`, `IsoVehicle`, `HandWeapon`, inventário e personagens), cujo resultado final depende do engine compilado.

## O que as fontes sustentam

| Área | Observação nos arquivos entregues | Consequência de design para SILÊNCIO |
|---|---|---|
| Casa por fora e por dentro | Não encontrei nestas fontes Lua uma implementação do renderer de paredes, transparência de janelas ou corte de telhado. A renderização/visibilidade interna do PZ depende do engine compilado e não está demonstrada pelo inventário do JAR. | Cada prédio SILÊNCIO deve ter geometria de cômodo única para movimento/colisão, mas dois estados de apresentação: exterior com fachada opaca e aberturas de janela; interior do cômodo atualmente ocupado, com teto e paredes de corte ocultos/baixos. Não carregar nem desenhar os móveis das outras unidades. Mudança de estado por entrada/saída sem alterar geometria ou colisão. Isso é proposta para o nosso renderer, não uma conclusão de como PZ implementa o seu. |
| Portas e janelas residenciais | `ISOpenCloseDoor.lua` vira o personagem para o objeto e termina chamando `ToggleDoor`. `ISOpenCloseWindow.lua` vira para o objeto e chama `openWindow`/`closeWindow`. As operações são rápidas/curtas neste wrapper Lua; estado de tranca e colisão dependem também do engine. | Interação no alcance, alinhamento e estado explícito aberta/fechada/trancada; bloquear passagem enquanto fechada. Preservar a mesma porta como conexão entre dois espaços e spawnar Caio na âncora do lado oposto. Janela aberta não vira porta: atravessar é uma ação própria. |
| Atravessar janela | `ISClimbThroughWindow.lua` recusa a ação se `canClimbThrough` negar para janela, moldura ou barreira equivalente; escolhe orientação a partir da face e inicia a ação com custo metabólico de salto. | Separar `abrir janela` de `pular pela janela`; exigir abertura/estado transponível, espaço livre no outro lado e ação animada que termine em posição navegável. Não teletransportar através da parede. |
| Armário/recipiente e loot | `ISOpenContainerTimedAction.lua` pede conteúdo apenas quando o recipiente ainda não foi explorado; depois abre ou recicla painel do recipiente. `ISInventoryTransferAction.lua` valida origem, destino, presença do item, espaço e regras do container antes de transferir. | Implementar um painel de loot reutilizável com estado de explorado persistente. Só revelar conteúdo ao abrir de perto; impedir transferência se Caio se afastou, item mudou ou destino não comporta o item. Gavetas, armários e porta-malas podem ser recipientes distintos com limites próprios. |
| Equipar e recarregar arma | `ISEquipWeaponAction.lua` confirma o item no inventário e usa ação/animação de equipar. `ISReloadWeaponAction.lua` exige arma primária, busca munição/estado de câmara e calcula tempos com modificadores. Os acertos e o dano não são calculados nesses wrappers. | Arma tem estado inventário → equipada, mão/pivô/animação; munição e durabilidade são recursos. Evitar ataque se o jogador só estiver desarmado? Em vez disso permitir empurrar/esquivar e fugir. O golpe deve validar alcance, direção e obstáculo no instante de contato, depois alterar a saúde visível do infectado. |
| Veículo e chave | `ISStartVehicleEngine.lua` só inicia com personagem no banco do motorista e testa no inventário uma chave que corresponda ao `keyId` antes de `tryStartEngine`. `ISHotwireVehicle.lua` executa ação temporizada e passa nível de Eletricidade a `tryHotwire`. `ISOpenVehicleDoor.lua` anima porta, respeita tranca e considera chave no inventário/ignição; veículo alarmado pode disparar alarme na primeira entrada. | Chave precisa ser objeto encontrado com ID ligado ao veículo. Interação deve mostrar porta/tranca e chave correspondente; entrar, sentar, fechar porta, ligar e dirigir são estados separados. Hotwire é uma rota mais arriscada, com tempo e chance/condição, não atalho invisível. |
| Janelas de veículos | `ISOpenCloseVehicleWindow.lua` anima um delta e só completa se janela não destruída, a peça instalada e o estado realmente mudar. `ISSmashVehicleWindow.lua` produz ferimento por vidro quando mãos estão sem proteção, de acordo com o wrapper Lua. | Carros devem ter estados visuais e colisores para vidros/portas e consequências claras; vidro quebrado não deve continuar como janela intacta. A animação comunica o alcance da ação. |
| Veículos estacionados/danificados | `VehicleZoneDefinition.lua` define grupos de distribuição por zona, tipos de veículo, chance de dano em peças, qualidade-base e alguns campos de condição inicial. `Vehicles.lua` contém rotinas de manutenção/deterioração de partes (incluindo pneus/suspensão/freios), mas não prova a física completa de colisão, geração de wrecks ou mudança automática de um carro normal para capotado. Parte da simulação continua no engine/dados ainda não auditados. | No SILÊNCIO, guardar condição visual e funcional como estado persistente independente: estacionado intacto, avariado/colisão narrativa, capotado/destroço. Só mudar por evento de colisão/missão autorado. Carro de cenário continua estático e simples. |
| NPCs e infectados | `ZombiesZoneDefinition.lua` associa zonas/ambientes a roupas, gênero, chance e papéis obrigatórios em salas. Esse arquivo não prova rota de patrulha, perseguição ou ponto de origem de cada zumbi. | Spawns de fase precisam declarar âncora, sala/rua, condição de missão, destino e rota caminhável; esconder personagem/infectado até a fase do evento e posicioná-lo em origem compatível com a navegação. Separar `origem narrativa` de `destino atual`. |
| Animais | `RaccoonDefinitions.lua` expõe parâmetros de espécie como `wanderMul`, fuga de humanos, `idleTypeNbr` e `canClimbStairs`; as rotinas e aparência final dependem de engine/recursos. Na consulta limitada ao diretório `media/lua/shared/Definitions/animal`, os nomes encontrados não incluem definição chamada Cat ou Dog; isso não prova inexistência em todos os binários/versões. | Aproveitar princípios, não o código: rotina por espécie, navegação sobre superfícies autorizadas, pose/locomoção por estado e perigo. Para gato/cachorro do SILÊNCIO, definir o comportamento explicitamente nos dados do jogo e usar assets próprios; não afirmar que o PZ fornece essas rotinas específicas. |

## Proposta de fluxo narrativo e combate para a Fase 1

O personagem já pode ser atacado no encontro do beco. O combate inicial precisa ensinar uma resposta antes de exigir vitória: um empurrão/esquiva com janela curta, uma arma improvisada acessível no trajeto (por exemplo, objeto pesado já coerente com a casa/rua) e uma opção de recuo para terreno aberto. O teste de dano deve ser por contato único em animação, direção e alcance, não por repetição do botão durante toda a animação.

Cada infectado deve possuir `maxHealth`, `health`, estado (`approach`, `windup`, `attack`, `stagger`, `down/dead`) e sua própria rota de navegação. Mostrar uma barra compacta junto ao alvo somente quando selecionado, atingido recentemente ou dentro do foco/percepção; manter cor/valor em HUD acessível. A barra precisa reduzir no impacto confirmado e refletir stagger/queda, sem texto flutuante constante. Uma barra visível antes do primeiro golpe não substitui leitura de postura e telegraph do ataque.

Para a missão, usar dados explícitos de grafo: `trigger → spawn/entrada → ponto de conversa ou combate → objetivo → saída/retorno`. Cada NPC precisa de ponto inicial e rota válida; cada diálogo começa por contato próximo/visível ou escrita/celular, respeitando que Caio é surdo. Uma conversa à distância não deve fornecer texto como leitura labial.

## Limites e próximos itens de evidência

- Este material não demonstra o desenho exato de uma casa vista por fora/dentro, transparência de paredes, AI completa, dano em Java ou simulação de batidas de carro. Essas perguntas seguem parcialmente respondidas até uma ferramenta JEB operante ou documentação do engine as esclarecer.
- Não copie assets, scripts ou animações distribuídos com PZ. Reproduza apenas padrões de fluxo com arte, parâmetros e lógica originais para SILÊNCIO.
- Não alterar nem instalar decompiladores nesta análise. Quando JEB MCP estiver disponível, reusar o mesmo JAR e o SHA acima; abrir focado em renderer/visibility, hit processing, pathfinding e veículos, mantendo as saídas como evidência REA separada de código Lua.

## Hashes das fontes consultadas nesta revisão

Os caminhos são relativos a `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`. Hash identifica exatamente o arquivo lido e permite repetir a consulta se a instalação mudar.

| Arquivo | Bytes | SHA-256 |
|---|---:|---|
| `media/lua/shared/TimedActions/ISOpenCloseDoor.lua` | 1348 | `7fc96ffa96f420640be769b0cc05c45281892aa994a453fc993733ee23fa2c21` |
| `media/lua/shared/TimedActions/ISOpenCloseWindow.lua` | 1171 | `8c1f81a01b79e1f95fa9793791f59f0ff4f1aeb6cec561f8366ae7f79ed1bfc7` |
| `media/lua/client/TimedActions/ISClimbThroughWindow.lua` | 2468 | `8e30e00d949a51c9652e295671df0e7700e5480de0355abf45e73e518abcb3f3` |
| `media/lua/client/TimedActions/ISOpenContainerTimedAction.lua` | 2234 | `7d8d0a753878f4839af254736a2dafdaeda97fd0cb9660514b6b68cd3fb5619f` |
| `media/lua/client/TimedActions/ISInventoryTransferAction.lua` | 33587 | `96ee554609f9ae029809643d50e4f31dbc5a7d21a558934be0804fd909c345b4` |
| `media/lua/shared/TimedActions/ISEquipWeaponAction.lua` | 11763 | `5aaf0e6942d83caed3df3acae63aa10c3b77bf9618208067b81d579a6e2bf66f` |
| `media/lua/shared/TimedActions/ISReloadWeaponAction.lua` | 20343 | `e85cd77ded08a1b2e6957fd1c810ed5bd58b6fa84c157c3f34a16f7b750fe6d8` |
| `media/lua/shared/Vehicles/TimedActions/ISHotwireVehicle.lua` | 1480 | `192a302c881fcf444e32b75b640dde92eb19c82756a1a2e2247dc14844fee0b5` |
| `media/lua/shared/Vehicles/TimedActions/ISStartVehicleEngine.lua` | 1392 | `feea686c3411171f2f619e9ec8447e91cebd65999dcf8748df26360a4ffea733` |
| `media/lua/shared/Vehicles/TimedActions/ISOpenVehicleDoor.lua` | 5074 | `2c5efd1514cfa5a528b60f66a8f042ea18220221578435ba30ad609151aa8d9a` |
| `media/lua/shared/Vehicles/TimedActions/ISOpenCloseVehicleWindow.lua` | 2120 | `145b348c07165ab4679f99725d6f8a840793c6a0e045d48acb1ea00dbd46cc9c` |
| `media/lua/shared/Vehicles/TimedActions/ISSmashVehicleWindow.lua` | 2527 | `56e12c2c8af523d5311c66f8e0d0f04d3e0ba56218fb015114e846895c197d9f` |
| `media/lua/shared/NPCs/ZombiesZoneDefinition.lua` | 32172 | `998f31d6834c80d10cb25b817e612f4927bedfe14ce396ecee9ca798f0cb58c6` |
| `media/lua/shared/Definitions/animal/RaccoonDefinitions.lua` | 16790 | `55185497017826ae3a1d3f3e980f963de29644797ea4d992d40ea9e483ca502c` |
| `media/AnimSets/player/shove/ShoveDefault.xml` | 2506 | `a0209e392c0fc2380717423219cfd061561635be19d08665dd710e5f7b00b7bd` |
| `media/lua/shared/VehicleZoneDefinition.lua` | 38879 | `691d11853557e03c966a5565369f50f5169509394ae3e111f0f4b58e82576892` |
| `media/lua/server/Vehicles/Vehicles.lua` | 60407 | `a9da37d058f555f54bd8aeb52da9891ca2069c78686f068dcbbfba0c92d3ce09d` |
