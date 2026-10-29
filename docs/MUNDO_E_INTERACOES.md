# Mundo explorável conduzido pela história — proposta para fase 01

Pedido do usuário: liberdade para entrar em ruas paralelas, encontrar itens e sofrer riscos, com conclusão da missão dependendo dos acontecimentos da história. A versão 0.4 implementou as interações domésticas básicas e o prédio conectado; a rua opcional com encontro próprio permanece proposta futura. Estado atual: [PREDIO_04.md](PREDIO_04.md).

## Estado anterior à versão 0.4

- Cama: salva progresso; com entrega, notícia, encontro resolvido, pulso e mensagem de Helena, conclui a fase. Caio ainda não se deita visualmente.
- Cadeira, sofá, armário e notebook: mobiliário visual com colisão quando aplicável; sem ação de sentar, abrir ou navegar.
- Cidade: espaço percorrível com pontos interativos, animais, coleta e encontro roteirizado. Não existe ainda um sistema geral de encontros em cada rua extra.

## Regras propostas

Manter o bairro como área aberta compacta, com caminhos conectados e interiores feitos à mão. O diário conserva o objetivo principal e o mapa destaca destinos conhecidos; becos e casas acessíveis podem conter descobertas opcionais. Entrar numa rua alternativa não avança marcos principais. Voltar ao caminho principal sempre é possível.

A história acompanha eventos, não uma sequência exata de passos. Explorar antes não entrega o adaptador, não resolve o encontro, não lê notícias e não conclui o pulso automaticamente. O jogador precisa realizar as ações da missão. Itens críticos não aparecem como recompensas aleatórias, não podem ser consumidos/perdidos de forma que bloqueie o capítulo. Descobertas opcionais têm identificador estável, coleta única persistente e consequências claras.

Evitar ataques aleatórios na manhã ainda normal: isso enfraqueceria o contraste do primeiro pulso. Um desvio antes dele pode ter sinais estranhos, pessoa hostil localizada ou recurso; depois do pulso o risco pode aumentar. Dar aviso visual/sonoro, espaço para fugir e alternativa sem combate. Ao abrir leitura ou menu, respeitar a pausa do beta. Inimigos não aparecem dentro do apartamento seguro, sobre o jogador ou na passagem de porta/escada.

## Primeiro trecho opcional sugerido

Proposta nova, não informação do PDF: uma rua lateral com um pequeno pátio conectada à rota da mercearia, com saída de volta ao bairro. Antes do pulso: explorar, observar um bilhete ambiental e encontrar uma atadura extra de coleta única. Depois do pulso: encontro opcional sinalizado, com rota de fuga; nenhuma chave de missão como prêmio. Limitar o primeiro lote a esse trecho para testar legibilidade, colisões, recompensa e retorno antes de ampliar o bairro. Não criar agora uma cidade procedural infinita.

## Interações domésticas propostas

| Ação | Comportamento | Arte necessária | Regra de missão |
|---|---|---|---|
| Deitar | Aproximar, sentar, deitar; botão levantar | Caio entrando/saindo da cama e pose deitado | Descansar não pula tarefas nem horário crítico; terminar fase só pelas condições existentes |
| Sentar na cadeira | Reservar assento, alinhar pés/quadril, sentar e levantar | Ciclos e máscara de oclusão da cadeira | Opcional; libera o assento ao levantar |
| Sentar no sofá | Mesmo fluxo, encaixe no sofá | Ciclos e camada frontal do sofá | Opcional, sem curar ferimento automaticamente |
| Abrir armário | Aproximar, abrir portas, mostrar conteúdo e fechar | Armário fechado/aberto e pose de alcance | Conteúdo original persistente, sem loot infinito ou item crítico escondido sem indicação |
| Usar notebook | Sentar, abrir tampa, entrar em tela interativa, fechar/sair | Tampa aberta/fechada, pose de digitar, interface | Notas locais e pistas opcionais; conteúdo narrativo novo precisa ser revisado; sem internet real nem reproduzir sites |

Cada objeto precisa de ponto de aproximação livre, âncora de pose, direção de uso e espaço de saída. Impedir atravessar móvel para alinhar a animação. Durante uma ação, interromper a navegação; levantar devolve controle somente numa posição válida. Persistir o conteúdo do armário, não uma pose intermediária que prenda Caio ao carregar save. Pausa/sair e interação repetida devem ser seguros. Todas as ações têm equivalente por teclado/toque, com rótulo contextual.

## Ordem de implementação

1. Estados e âncoras de interação no apartamento; cama/sofá/cadeira com levantar seguro.
2. Armário e notebook com interfaces locais e persistência.
3. Uma rua opcional, item único, encontro sinalizado e rota de fuga.
4. Jogar o capítulo completo, verificando liberdade de ordem sem quebrar os marcos; testar depois no celular.

Critérios: nenhum atravessamento de parede/móvel, coleta não duplica após reload, interação não conclui missão cedo, sentar/levantar não prende o jogador, visitas opcionais não impedem voltar à história. Vídeos são acabamento posterior: microações permanecem interativas no motor.
