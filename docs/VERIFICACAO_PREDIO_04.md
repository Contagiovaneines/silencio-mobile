# Verificação — prédio e Android 0.4

Data: 28/10/2026. Flutter 3.47.7, Flame 1.38.2. Dispositivo físico: Samsung Galaxy A15 SM-A156M, Android 16, paisagem 2340×1080, densidade informada pelo aparelho 450 dpi.

## Verificações automatizadas

- `flutter analyze --no-pub`: nenhuma ocorrência no lote de revisão.
- `flutter test --no-pub`: 27 testes aprovados na execução final.
- `flutter build apk --release --no-pub`: concluído, APK universal aproximadamente 53,9 MB.
- A build web também é mantida para teste no PC; o Android é a entrega principal desta revisão.

Os testes novos percorrem a coleta física dos itens, porta 203, dois lances de escada, entrada residencial, caminho até a mercearia e retorno ao apartamento. Verificam posições livres durante a passagem, divisórias/unidades separadas, banheiro nos dois sentidos, armazenamento sem duplicação, consumo persistente da geladeira e ações domésticas sem avançar a missão. Incluem a mensagem correta do primeiro andar e leitura de saves sem os novos campos. Os testes existentes preservam o percurso narrativo, inventário, combate não letal, colisão e interface em duas dimensões.

## Instalação e preservação

Pacote: `dev.silencio.silencio`, versão 0.4.0, versionCode 4. Atualização instalada com `adb install -r`, sem desinstalar nem limpar dados. A cópia anterior das preferências foi guardada em `docs/backups/android-antes-04/FlutterSharedPreferences.xml`. Esse aparelho tinha o slot antigo v1; ele foi preservado. O percurso atual utiliza v2, sem conversão automática da história antiga.

O APK final foi instalado novamente após os ajustes visuais. O menu apresentou Continuar, confirmando que o progresso v2 criado durante a revisão permaneceu após a atualização. SHA-256 do arquivo instalado no aparelho conferido contra a cópia local:

`c751a021a80e0f81bf9f2caf981718c3cc0382e71eef92ca3a8d9ec213e26527`

Entrega local: `build/releases/silencio-0.4.0-android.apk`. Assinatura de desenvolvimento existente, sem publicação em loja.

## Conferência visual no aparelho

Foi observado o caminho da rua pela porta residencial ao hall, subida com parada no primeiro andar, segundo lance ao segundo andar, passagem para dentro do 203 e ação de sentar no sofá com pose própria e botão Levantar. O retorno ao controle foi observado no apartamento. Menu, abertura, botões de toque e mensagens foram inspecionados por captura de tela e hierarquia acessível.

Capturas em `docs/screenshots/`: `android04-entrada.png`, `android04-hall.png`, `android04-primeiro-andar.png`, `android04-segundo-andar.png`, `android04-retorno-203.png`, `android04-sofa-sentado.png`, `android04-levantar-sofa.png` e `android04-instalado-final.png`.

Algumas capturas registram versões intermediárias da própria revisão: a última atualização remove chuva visual do hall, melhora a leitura da parede frontal e corrige a legenda de chegada ao primeiro andar. A captura do menu instalado é posterior à instalação final. Cama, notebook, geladeira e armário têm cobertura automatizada, mas a revisão completa de suas ações no aparelho ainda não foi concluída. Não apresentar o teste como uma partida Android integral do capítulo.

## Amostra de execução

No trecho observado antes da última atualização visual, nenhum registro de erro fatal/Flutter foi encontrado nas últimas 400 linhas do processo do jogo. Isso não prova ausência de erros fora da janela observada. Dados: `android04-erros.json`.

Memória: TOTAL PSS 332.007 KiB, aproximadamente 324,2 MiB; TOTAL RSS 372.320 KiB. Registro: `android04-memoria.txt`.

Compositor: 63 apresentações válidas em cerca de 1,066 s; intervalo mediano 16,660 ms e percentil 95 de 16,854 ms. É uma amostra curta de apresentação, compatível com cerca de 60 apresentações/s naquele trecho, não um benchmark sustentado de FPS do capítulo. Registros: `android04-surface-latency.txt` e `android04-amostra-compositor.json`.

## Limites

Ainda faltam teste prolongado de aquecimento/bateria, revisão auditiva, outros aparelhos, ciclos completos de animação e acabamento da fachada. A escada permanece uma transição curta entre patamares, com movimento encenado. Unidades vizinhas ficam fechadas nesta fase. Streaming de sprites por bairro e rotinas gerais de moradores não foram concluídos. [Estado detalhado](PREDIO_04.md).
