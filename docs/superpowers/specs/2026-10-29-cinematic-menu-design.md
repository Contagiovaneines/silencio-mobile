# Menu principal cinematográfico — design

## Intenção

Atualizar somente o menu principal de SILÊNCIO para aproximá-lo da referência enviada: Santa Aurora chuvosa às 07:12, torre de transmissão, Caio observando a cidade e ações de jogo em uma hierarquia clara. O menu deve continuar sendo interface Flutter real, responsiva e conectada ao save e às opções existentes.

## Objetivos

- Usar duas artes originais separadas: panorama da cidade e recorte transparente de Caio.
- Animar chuva, neblina, beacon da torre e respiração de Caio em camadas leves.
- Organizar Continuar, Novo jogo, Opções e Extras; desabilitar Continuar quando não houver save.
- Manter idioma, alto contraste, redução de movimento e ações de Jornada/replay já existentes.
- Funcionar em 4:3, 16:9 e retrato 9:16 sem deformar o cenário ou esconder os controles.

## Fora do escopo

- Alterações no mapa, ciclo de dia/noite jogável, história ou sistemas de combate.
- Novas funções vazias em Extras, áudio sem arquivos existentes, bibliotecas runtime ou consumo dos créditos PixlPerfect.
- Alteração do save atual, configurações globais ou animações de Libras não validadas.

## Abordagem escolhida

1. Reutilizar o `GameShell` e os callbacks/estado de save existentes; menor risco de regressão.
2. Renderizar panorama e Caio como imagens independentes, com chuva/neblina/beacon em `CustomPainter` e respiração sutil no recorte; dá movimento sem tornar a imagem de fundo uma tela inteira estática.
3. Reorganizar os controles com componentes Flutter reais. Extras conterá somente Jornada e replay da abertura, que já existem.

As artes serão geradas localmente para esta tarefa e não consumirão créditos externos.

## Validação

- Testes de widget em 4:3, 16:9 e 9:16; confirmar que Continue reflete save e Extras navega para ações reais.
- `flutter test`, `flutter analyze --no-pub`, build web release e inspeção visual pelo navegador.
- Nenhum toque ou operação pode substituir o save original do usuário durante a QA.
