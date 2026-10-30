# Produção visual — fase 01

Este pacote organiza prompts e quadros-chave estáticos para quatro vídeos futuros. As imagens provisórias já aparecem nos momentos correspondentes do beta; não são vídeos e não alteram a história nem as mecânicas.

## Começar

1. Abrir uma pasta dentro de `video/` e ler `PROMPT.md`.
2. Anexar as imagens de `assets/` ao gerador, indicando os papéis descritos. Não converter a folha de móveis inteira em cenário animado. WAVs são referências de pós-produção.
3. Gerar o vídeo com o prompt pronto; conferir anatomia, identidade, cenário e primeiro/último quadro.
4. Guardar o MP4 em `saida/`, com o nome indicado. Não apagar versões anteriores.
5. Avisar que os arquivos estão prontos para integração. A integração e os eventos do jogo serão revisados depois.

| Pasta | Duração alvo | Uso |
|---|---:|---|
| video/01_abertura | 8 s | Quadro da cidade antes das cinco páginas originais da abertura |
| video/02_primeiro_pulso | 6 s | Quadro do pulso antes da narração e do diálogo |
| video/03_mensagem_helena | 4 s | Imagem junto à mensagem interativa de Helena |
| video/04_retorno_e_cama | 6 s | Quadro de encerramento da fase |

Cada pasta contém referências, `assets/keyframe_placeholder_v01.png`, proveniência SHA-256 em `ASSETS.json`, prompt e destino do vídeo. `video/manifest.json` indica também o asset provisório usado no jogo. Os quatro quadros foram criados originalmente para SILÊNCIO; não vieram dos jogos de referência. Os MP4 continuam aguardando produção.

## Padrão e referências

`referencias/santa_aurora_conceito_v01.png` é uma ilustração nova gerada com imagegen integrado em 28/10/2026, usando a captura atual do apartamento como referência de estilo. É conceito visual, não screenshot nem mudança da planta jogável. Foi inspecionada: rua molhada, perspectiva isométrica, luz âmbar, sem texto/HUD. Os cenários do beta são a referência para a geometria real. O PNG fonte gerado foi preservado; nenhuma imagem foi alterada por script.

O retrato de Caio fixa a identidade; sprites existentes fixam roupa e escala. A arte atual ainda é provisória. A imagem da cidade não autoriza acrescentar novos acontecimentos ao roteiro.

Prompts de animação interativa estão em `animacao/`. Referências analisadas e plano de mundo explorável: [MUNDO_E_INTERACOES.md](../docs/MUNDO_E_INTERACOES.md) e [REFERENCIAS_THREADS.md](../docs/REFERENCIAS_THREADS.md).

## Integração dos quadros e troca por vídeo

O jogo exibe os PNG `video_placeholder_...` enquanto não há MP4. Quando o vídeo for entregue, a integração deve trocar somente a mídia do slot indicado no manifesto. Não implementar um evento narrativo dentro do arquivo: o motor controla progresso e checkpoint. Pular, concluir normalmente ou falhar a reprodução devem chegar ao mesmo estado, uma única vez. Retomar não pode duplicar itens ou finalizar a fase cedo. Vídeos não substituem diálogos, escolhas, colisão ou exploração. Texto/legendas ficam no motor; respeitar efeitos reduzidos e áudio desligado. Porta e escada continuam no motor.

Ainda não existe player de vídeo integrado. Nenhum desempenho móvel foi validado para essa mídia. O formato inicial é MP4 H.264 SDR yuv420p horizontal; o tamanho e a resolução de distribuição serão ajustados ao aparelho, preservando proporção. Até lá, cada evento usa um quadro estático original como substituto.

## Atualizar cópias

`tools/prepare_video_pack.py` prepara os quatro pacotes a partir dos arquivos do projeto, sem modificar o jogo. Antes de editar manualmente um PROMPT.md gerado, atualizar o texto no script também; executar novamente substitui os prompts e cópias de referência, nunca os MP4 da pasta saida.
