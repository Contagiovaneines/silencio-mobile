# Reuso da primeira tentativa — beta 0.4.1

Data: 28/10/2026. Fonte consultada: `C:/Users/giovane/Downloads/Silencio-main/Silencio-main`. Essa pasta permaneceu sem alterações e não foi executada/importada no editor Godot.

## O que foi encontrado

A tentativa antiga é um projeto Godot com apresentação em telas e exploração lateral. Menu, abertura e mapa são construídos em GDScript. O fluxo documentado possui onze áreas e sistemas de câmera por zonas, transições e checkpoints por identificadores. Há diferenças importantes de combate, armas e conteúdo em relação ao beta isométrico atual.

A abertura antiga usa imagens, diálogo, deslocamento lento de câmera e transições; não foi encontrado um arquivo de vídeo MP4/WebM/OGV no projeto. Portanto, o reuso imediato foi da apresentação ilustrada, não de um player de vídeo. Os prompts de vídeos futuros continuam separados.

## Integrado no Flutter

| Ideia da primeira versão | Adaptação atual |
|---|---|
| Menu atmosférico com configurações | Capa de Santa Aurora, cartão do progresso atual, Configurações e Jornada acessíveis antes de jogar |
| Abertura com quadros ilustrados | Duas artes do laboratório antigo, preservando os cinco textos atuais do prólogo |
| Controle de sequência narrativa | Leitura manual por padrão, Anterior/Avançar/Pular, modo automático opcional e comandos de teclado |
| Mapa com capítulos disponíveis/bloqueados | Tela Jornada com doze posições; apenas fase 01 inicia jogo; demais claramente em produção |
| Separação de apresentação e mundo | Ilustrações limitadas ao menu/prólogo; mapa local, construção e colisões continuam no Flame |

A Jornada é acessível pelo menu e pelo mapa local. Fechar retorna à tela de origem. Visitar capítulos futuros não altera inventário, marcos ou desbloqueios. Os nomes futuros não foram transplantados em massa do projeto antigo: 01 e 02 usam os títulos já conhecidos no beta; os restantes permanecem genéricos até revisão do roteiro.

As configurações reutilizam as mesmas preferências de áudio, efeitos e tamanho de texto existentes. Nenhuma opção de idioma ainda indisponível é apresentada como funcional. A preferência de avanço automático fica separada do save da campanha. Reassistir à abertura retorna ao menu e mantém inventário e progresso.

## Assets e preservação

Duas imagens foram copiadas da fonte: `subject07_lab.png` e `laboratory.jpg`, com novos nomes prefixados por `legacy_` na pasta de imagens do Flutter. A capa reutiliza `santa_aurora_conceito_v01.png`, que já existia neste projeto. Não foi produzida arte nova nesta revisão. Nenhum asset existente foi substituído.

`REUSO_PRIMEIRA_VERSAO_ASSETS.json` registra os três arquivos, origens e hashes. Os originais e cópias foram conferidos após a integração. O fundo de cidade devastada da tentativa antiga não foi usado para representar a manhã normal de Santa Aurora. A folha isométrica atual e a geometria jogável permanecem independentes dessas ilustrações.

Backup das fontes anteriores à mudança: `docs/backups/antes-menu-jornada-041.zip`.

## Oportunidades mantidas para revisão futura

- Câmera por zonas: útil quando houver novos interiores com enquadramentos diferentes; não introduzir uma segunda câmera concorrente.
- Checkpoints por área e ponto nomeado: úteis para migrações de mapas maiores. A revisão atual não troca o formato de campanha nem reinterpreta saves Godot como saves Flutter.
- Componentes de interação da tentativa antiga: boas referências de estados e prioridade, sem portar a física lateral para a navegação isométrica.

Armas, laboratórios exploráveis e cenas de outros capítulos não foram incorporados automaticamente. Precisam ser compatibilizados com o roteiro e com o escopo da fase 01.

## Verificações

- `flutter analyze --no-pub`: nenhuma ocorrência após os ajustes.
- `flutter test --no-pub`: 30 testes aprovados. Incluem menu/configurações/Jornada em 832×384 e 1366×768, retorno à origem, leitura manual/automática e preservação do save ao reassistir.
- Builds web release e APK release concluídas.
- Android instalado com `adb install -r`: versão 0.4.1, versionCode 5, no Galaxy A15. Menu novo e opção Continuar observados; retomada do mundo também observada. Não houve desinstalação ou limpeza de dados.
- Prévia web limpa em 58402: menu, configurações, seleção do capítulo 02 em produção e prólogo ilustrado observados. A origem anterior foi preservada, pois apresentava recursos antigos em cache. Não foi apagado o armazenamento do navegador.
- Nenhum erro fatal/Flutter encontrado no trecho de 300 linhas do processo Android observado; console web observado sem erros/avisos. Isso não substitui testes prolongados ou revisão de todas as telas em outros aparelhos.

Entrega: `build/releases/silencio-0.4.1-android.apk`, 61.842.543 bytes, assinatura de desenvolvimento. SHA-256 local conferido contra o APK instalado:

`eadbd927a44331c1614db644323f838eecf6d7778c7c5d1adbbfd199d5928e74`

Dados verificáveis em `VERIFICACAO_REUSO_041.json`. Capturas: `screenshots/android04-reuso041-menu.png`, `screenshots/reuso041-jornada-web.png` e `screenshots/reuso041-prologo-web.png`. O arquivo Android com sufixo jornada registra a retomada do mundo, não a tela Jornada; ele não é usado como evidência dessa tela.

Os limites artísticos e de otimização do prédio 0.4 continuam descritos em `PREDIO_04.md`; esta revisão melhora apresentação, não declara concluída a campanha inteira.
