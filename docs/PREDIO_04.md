# Prédio conectado — versão 0.4

## Implementação

Flutter + Flame preservados. `ResidentialLayout` é o dono da planta dos três pisos: limites externos, corredor, unidades, divisórias, aberturas e definições das portas. `WorldModel` usa esses dados na navegação e colisão; o renderer usa os mesmos dados para paredes, portas e aberturas frontais da fachada. Os objetos continuam sendo geometria e sprites com ocupação física, não um fundo único.

- Piso 2: apartamento 203 à esquerda na planta local; unidades 202 e 201 em sequência; corredor, Dona Inês e escada. Esta orientação preserva o início e a janela existentes; não reproduz literalmente a ordem esquerda/direita das ilustrações.
- Piso 1: corredor navegável e áreas separadas 103, 102 e 101.
- Piso 0: corpo do prédio, hall residencial, porta de entrada e ligação lateral válida com a garagem. A mercearia de Orlando permanece no local original do bairro.
- Dois lances com origem/destino explícitos: 2↔1 e 1↔0. A versão usa a transição curta com descida/subida encenada. Não é uma escada 3D continuamente navegável.
- Unidades vizinhas têm paredes e portas identificadas; estão fechadas para Caio nesta fase. Não há mobiliário completo ou novas missões inventadas para seus moradores.

## Porta e movimentação

203, banheiro e entrada usam o mesmo controlador de passagem. A chave continua obrigatória na 203. A aproximação escolhe o lado atual da porta, impedindo o pathfinding de dar a volta pelo prédio para alcançar o centro de uma porta fechada. A animação verifica o trajeto físico; escadas verificam a posição de chegada. A colisão fecha novamente ao término. Portas dos vizinhos comunicam que o acesso está indisponível.

Interações com objetos verificam distância e bloqueio por parede; móveis não impedem examinar o próprio objeto. As divisórias do banheiro continuam sólidas quando rebaixadas visualmente. Posições restauradas em unidades sem acesso são transferidas para um ponto seguro, conservando os eventos.

## Interior e ações

Banheiro separado, com porta, pia/espelho, vaso e chuveiro. Armário reposicionado para liberar a circulação. Geladeira e mesa de centro acrescentadas. Parede frontal pode rebaixar e ficar translúcida para leitura de Caio; a barreira física não muda. Guarda-corpos usam a mesma borda da planta. A fachada tem níveis, portas, aberturas e equipamentos de cobertura; o teto e os pisos superiores são retirados da vista no hall. Chuva visual não é desenhada dentro da área residencial térrea.

| Objeto | Ação |
|---|---|
| Cama | Pose de repouso e salvar; só encerra a fase quando os marcos originais estiverem concluídos |
| Sofá/cadeira | Pose sentada e levantar; o corpo físico conserva uma posição livre para retorno seguro |
| Armário | Guardar/retirar ataduras sem mover itens de missão; quantidade persiste |
| Geladeira | Uma porção de água que restaura fôlego; consumo persiste e não cura ferimentos |
| Notebook | Pose de digitar e apresentação do caderno/objetivos existentes; sem internet real ou novas revelações |
| Celular | Sistema existente de mensagens preservado |

As poses domésticas são uma folha RGBA original gerada com imagegen a partir da identidade existente de Caio. O PNG não foi alterado por script; os retângulos são amostrados diretamente. Ainda não são ciclos completos de sentar/levantar ou abrir com a mão. A folha de móveis original e os assets do usuário foram preservados.

## Persistência e desempenho

Formato v2 ampliado de maneira aditiva: piso 1, portas domésticas, ataduras guardadas e água da geladeira. Saves sem esses campos recebem valores iniciais válidos. Saves v1 permanecem preservados no slot anterior; não são convertidos automaticamente para o percurso atual. Poses intermediárias não são gravadas. O checkpoint conserva posições estáveis nas transições.

Pisos estáticos ficam em `ui.Picture`. Prédios, móveis, NPCs e veículos fora do enquadramento deixam de participar de parte do desenho/ordenação. Etiqueta contextual única por proximidade, com mais marcadores somente em Percepção. O conjunto de sprites ainda é carregado no início: streaming de assets por bairros será necessário ao ampliar o mapa, não foi apresentado como concluído.

Inês tem deslocamento curto no corredor com bloqueio por obstáculos e pelo jogador; os demais NPCs preservam os comportamentos da missão. Não existe ainda uma rotina geral de moradores entrando e saindo de todas as unidades.

## Acabamento restante

Fachada e instalações sanitárias ainda misturam arte em PNG com desenho no motor. A iluminação é composta por efeitos 2D e sombras simples; não há simulação física de reflexos ou luz dinâmica completa. Permanecem ciclos de animação completos, interiores narrativos dos vizinhos, expansão de ruas opcionais e testes prolongados em aparelhos. Esses itens não impedem o percurso funcional da fase 01.
