# Produção visual — fase 01

Este pacote prepara mídia futura. Não altera as mecânicas nem exige vídeos para jogar o beta.

## Começar

1. Abrir uma pasta dentro de `video/` e ler `PROMPT.md`.
2. Anexar as imagens de `assets/` ao gerador, indicando os papéis descritos. Não converter a folha de móveis inteira em cenário animado. WAVs são referências de pós-produção.
3. Gerar o vídeo com o prompt pronto; conferir anatomia, identidade, cenário e primeiro/último quadro.
4. Guardar o MP4 em `saida/`, com o nome indicado. Não apagar versões anteriores.
5. Avisar que os arquivos estão prontos para integração. A integração e os eventos do jogo serão revisados depois.

| Pasta | Duração alvo | Uso |
|---|---:|---|
| video/01_abertura | 8 s | Estabelecer Santa Aurora e apartamento |
| video/02_primeiro_pulso | 6 s | Pessoas param, Caio permanece consciente |
| video/03_mensagem_helena | 4 s | Inserto opcional; texto segue interativo |
| video/04_retorno_e_cama | 6 s | Encerrar a primeira fase sem revelar a próxima |

Cada pasta contém assets reais de referência, proveniência SHA-256 em `ASSETS.json`, prompt e destino do vídeo. `video/manifest.json` registra os eventos propostos. Os MP4 ainda serão produzidos pelo usuário. O pacote não inclui imagens/filmagens extraídas dos jogos de referência.

## Padrão e referências

`referencias/santa_aurora_conceito_v01.png` é uma ilustração nova gerada com imagegen integrado em 28/10/2026, usando a captura atual do apartamento como referência de estilo. É conceito visual, não screenshot nem mudança da planta jogável. Foi inspecionada: rua molhada, perspectiva isométrica, luz âmbar, sem texto/HUD. Os cenários do beta são a referência para a geometria real. O PNG fonte gerado foi preservado; nenhuma imagem foi alterada por script.

O retrato de Caio fixa a identidade; sprites existentes fixam roupa e escala. A arte atual ainda é provisória. A imagem da cidade não autoriza acrescentar novos acontecimentos ao roteiro.

Prompts de animação interativa estão em `animacao/`. Referências analisadas e plano de mundo explorável: [MUNDO_E_INTERACOES.md](../docs/MUNDO_E_INTERACOES.md) e [REFERENCIAS_THREADS.md](../docs/REFERENCIAS_THREADS.md).

## Integração futura e acessibilidade

Não implementar um evento narrativo dentro do arquivo de vídeo: o motor controla progresso e checkpoint. Pular, concluir normalmente ou falhar a reprodução precisam chegar ao mesmo estado, uma única vez. Interromper/retomar não pode duplicar itens ou finalizar a fase cedo. Manter apresentação atual como alternativa quando a mídia faltar. Vídeos não substituem diálogos, escolhas, colisão ou exploração. Texto/legendas ficam no motor; respeitar efeitos reduzidos e áudio desligado. Porta e escada continuam no motor.

Ainda não existe player de vídeo integrado. Nenhum desempenho móvel foi validado para essa mídia. O formato inicial é MP4 H.264 SDR yuv420p horizontal; o tamanho e a resolução de distribuição serão ajustados ao aparelho, preservando proporção.

## Atualizar cópias

`tools/prepare_video_pack.py` prepara os quatro pacotes a partir dos arquivos do projeto, sem modificar o jogo. Antes de editar manualmente um PROMPT.md gerado, atualizar o texto no script também; executar novamente substitui os prompts e cópias de referência, nunca os MP4 da pasta saida.
