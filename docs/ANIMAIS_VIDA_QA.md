# Rotinas originais de animais — integração de QA

O módulo `lib/game/animal_behaviour.dart` substitui movimento senoidal e elevação sem destino por uma pequena máquina de estados determinística. Os estados são `idle`, `walk`, `sniff`, `sleep`, `climb`, `mark` e `fly`. Não contém código nem assets extraídos de Project Zomboid.

## Contrato

Criar `AnimalBehaviourWorld(dogIsMale: true)` uma vez no WorldModel. Chamar `reset()` ao restaurar campanha. `actors`, `cat`, `dog` e `pigeon` expõem posição, direção, elevação visual separada, estado, tempo no estado, deslocamento acumulado, quadros e superfície atual. O modelo não muda o piso nem as coordenadas de Caio.

`update(delta, canOccupy: callback, playerPosition: Offset(...), isNight: bool, canUseSurface: callback)` usa passos internos de 1/60 e limita recuperações de frame longo a 250 ms. O callback de ocupação precisa avaliar a geometria térrea, paredes, móveis, veículos, NPCs e corpos no solo, excluindo o próprio ID. O raio sugerido é 0,18 unidade. A disponibilidade de superfície deve exigir carro parado; não assumir que um veículo futuro em movimento continue disponível.

Para poupar trabalho no mobile, o WorldModel pode atualizar este conjunto apenas enquanto o exterior está ativo. A busca em meia célula ocorre ao escolher destino, não a cada quadro. Os segmentos são verificados novamente ao andar, inclusive contra obstáculos móveis. Bloqueio não avança posição nem quadro de passada; há tentativa de novo caminho e espera se não houver rota.

`interact(id, canOccupy: callback)` devolve uma observação visual da ação atual; não pressupõe que Caio ouviu o animal. `takeEvents()` devolve eventos opcionais de voo/marcação, com fila limitada. Sons nunca são a única pista.

## Rotinas

- Breu inicia junto à fachada do residencial, sobe num apoio explícito do muro, observa, dorme, desce com verificação de pouso e percorre a rota até o sedã. No carro estacionado, a superfície é o teto, com ponto de embarque próprio. Só essas duas superfícies permitem elevar o gato; não se removem colisões de todos os carros ou paredes.
- Fubá percorre garagem, fareja, aproxima-se de um ponto junto à parede, marca se explicitamente macho e dorme num ponto livre. Uma instância configurada como fêmea fareja no mesmo ponto, sem entrar em marcação.
- Pingo caminha no chão e voa entre pousos definidos na praça. A posição muda durante o voo. Um destino ocupado não permite pousar dentro de um personagem; o pássaro espera em altura e termina a descida quando houver espaço.

As decisões não usam aleatoriedade nem dependem da taxa de renderização. As dimensões e posições devem ser revisadas se a planta do bairro mudar.

## Renderização

Usar `walkFrame` somente ao andar de fato; `flightFrame` é uma cadência distinta para asas. O desenho aplica `iso(position) - Offset(0,elevation)`. A sombra permanece no plano do chão e pode enfraquecer em altura. Um gato no teto do sedã precisa ser desenhado depois do carro, mesmo com x/y dentro do footprint: a regra comum de ordenar um ator interno antes do veículo não se aplica a uma superfície superior explícita.

`assets/images/animal_life_poses_v1.png` é uma folha original RGBA produzida com imagegen integrado a partir das identidades existentes de Breu e Fubá. Contém gato dormindo/subindo e cão dormindo/marcando. Fonte preservada, sem edição raster por script. Os retângulos e hash estão em `assets/data/animal_life_poses.json`. Não é ciclo completo nem conjunto de oito direções. As seis imagens de locomoção existentes são diferentes em bytes e em ocupação alfa; devem continuar sendo selecionadas por deslocamento, em vez de manter o gato sempre no quadro zero.

Prompt usado: criar quatro poses isoladas em uma linha, fundo transparente, Breu preto e Fubá caramelo conforme as referências; gato enroscado dormindo, gato subindo apoio invisível, cão dormindo e cão macho com uma perna traseira levantada junto a parede invisível; anatomia correta, sem fluidos/genitais, sem cenário, texto ou marcas; câmera isométrica e acabamento pixelizado pintado. Essas imagens são próprias do SILÊNCIO, não recurso de outro jogo.

## Cobertura proposta

`test/animal_behaviour_test.dart` cobre rotinas de muro/carro e solo válido na geometria real, bloqueio sem patinação, espera de pouso do gato, condição macho/fêmea e equivalência das atualizações em 30/60 Hz. O agente integrador executa os testes e a análise junto do projeto completo; este módulo não declara por conta própria que o gate passou.
