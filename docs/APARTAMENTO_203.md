# Apartamento 203 — versão 0.3

Registro histórico da versão 0.3. Na versão 0.4 o primeiro andar passou a ser navegável, o banheiro foi separado e foram acrescentadas ações domésticas. Consultar [PREDIO_04.md](PREDIO_04.md) para o estado atual.

## Decisão de cenário

Caio mora no apartamento **203, no segundo andar**. Dona Inês é a vizinha do **202**. O número do andar é uma decisão deste projeto, aceita após a proposta na conversa; não era uma informação definida no PDF.

A referência enviada pelo usuário orienta móveis detalhados, madeira, luz quente, sombras, plantas, quadros, tapete, cozinha compacta e interface limpa. A planta permanece compacta, com a circulação necessária para os objetivos da fase.

## Saída e retorno

- A porta 203 é um objeto real do cenário. A chave é necessária para iniciar a passagem.
- Caio aproxima-se da porta; a folha gira na dobradiça; ele atravessa e a porta fecha. O mesmo funciona para entrar.
- Atravessar a porta leva ao corredor do segundo andar, com Dona Inês, porta 202, elevador e escada.
- A escada tem uma passagem encenada, com indicação do primeiro andar e chegada ao térreo. O primeiro andar não é uma área explorável nesta versão.
- O térreo conecta escada, garagem e rua. A subida retorna ao corredor e permite entrar novamente no 203.
- O elevador está sinalizado em manutenção; a rota funcional desta fase é a escada.

Não há barra ou tela longa de loading entre os pisos. A porta é mostrada continuamente. A escada usa uma transição escura curta no meio da descida/subida, com os dois pisos já preparados em memória. Isso não equivale a um prédio 3D contínuo com todos os pavimentos exploráveis.

## Colisão, câmera e progresso

`Campaign.floor` identifica o piso: 2 ou 0. Pessoas, móveis, pontos de interação, edifícios e veículos são filtrados pelo andar. Bordas do segundo andar e porta fechada bloqueiam o movimento. A câmera acompanha o personagem e troca de referência sob a transição da escada.

Saves antigos sem campo de andar têm o piso inferido pela posição; itens e eventos são preservados. Não se grava a posição intermediária de uma porta/escada: o checkpoint conserva o último estado estável e é atualizado na chegada. O snapshot do checkpoint é capturado antes da espera de escrita.

A navegação mantém o destino quando um obstáculo móvel interrompe o trajeto e tenta recalcular o caminho. Ao apontar para uma porta fechada, aproxima-se do ponto alcançável do lado atual, sem planejar atravessar a parede.

## Arte importada

- `assets/images/apartment_furniture_v1.png`: PNG RGBA original gerado com a habilidade imagegen, a partir da direção visual da imagem enviada. Contém cama, armário, escrivaninha, cozinha, estante e sofá.
- `assets/data/apartment_furniture.json`: retângulos de cada objeto e SHA-256. O resultado não ficou em uma grade regular; os objetos foram inspecionados e são amostrados diretamente pelo renderer, sem modificar o PNG fonte.
- Paredes, janela, quadros, tapete, porta, escada e elevador são desenhados no motor. Os originais do pacote de assets do usuário continuam preservados.
- A transparência de móveis que cobrem o protagonista melhora a leitura. As etiquetas de interação são desenhadas após o cenário.

Os móveis são uma primeira revisão integrada e jogável, não aprovação de toda a arte final. Animações completas de abrir porta com mão/maçaneta e de pisada em cada degrau ainda podem receber novos quadros próprios; nesta versão, o motor encena a passagem com os ciclos existentes de Caio e a porta articulada.
