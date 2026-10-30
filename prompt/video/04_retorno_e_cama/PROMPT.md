# 04_retorno_e_cama

## Referências

Anexar os arquivos de assets como referências, não como quadros de colagem. Retratos fixam identidade; sprites fixam roupa e proporção; captura fixa cenário; WAV é guia para pós-produção, não trilha obrigatória. `assets/keyframe_placeholder_v01.png` é o quadro estático que o jogo mostra enquanto o vídeo não existe.

## Prompt pronto

SILÊNCIO: jogo mobile em paisagem, cenário isométrico 2.5D com textura pintada e acabamento pixelizado discreto. Brasil contemporâneo, Santa Aurora. Exteriores azul-petróleo/cinza dessaturados, madeira e luz âmbar nos interiores. Preserve perspectiva, proporções e identidade das referências; não transformar em anime de luta, live-action ou 3D brilhante. Caio tem cabelo preto curto e bagunçado, jaqueta escura, mochila e aparência do retrato fornecido. Caio não fala nem narra. Não inventar diálogos, roupas, poderes, monstros, ferimentos ou acontecimentos. Sem HUD, palavras, legendas, marcas ou logotipos gerados; textos serão aplicados no jogo. Sem flashes repetidos, câmera trêmula, morphing, objetos duplicados ou mudança da planta. As capturas do beta contêm HUD: usar somente cenário e composição como referência, excluir toda a interface do resultado. Nunca gerar vídeo dentro de uma folha de sprites ou colagem.

Interior do apartamento 203 ao fim do dia, mesma cama, janela, madeira e disposição da referência. 0–2s: Caio já está junto à cama; ele senta com movimento contido. 2–4.5s: deita com anatomia e escala consistentes, mochila fora do colchão, sem se fundir ao móvel. 4.5–6s: câmera fixa e luz quente mais baixa; quadro final calmo. Não acrescentar sonho, ataque, torre acesa ou despertar às duas. A conclusão e o texto sobre o próximo capítulo serão mostrados pelo motor. Se o gerador não preservar a anatomia, usar apenas plano do quarto e realizar o deitar por sprites no jogo; não aprovar deformações.

Vídeo único de 6 segundos, horizontal 16:9, alvo 1920×1080, 24 fps, sem áudio embutido. Movimento discreto, câmera isométrica coerente. Guardar primeiro e último quadro para conferir continuidade.

## Entrega

Salvar `saida/silencio_f01_retorno_v01.mp4`. MP4 H.264, yuv420p, SDR. Se o serviço exportar outra resolução, manter 16:9 e informar; não esticar a imagem. A taxa e compressão final serão ajustadas na integração. Versões novas usam v02, v03, sem sobrescrever a aprovada.

## Integração

Somente ao usar a cama após canLeave + pulse + night. Não acionar ao salvar cedo; nenhuma prévia do capítulo 2.

O jogo usa atualmente `assets/images/video_placeholder_04_retorno_v01.png` como imagem provisória nesta cena. Ao receber e aprovar o MP4, trocar a mídia deste slot pela reprodução do vídeo e manter texto, acessibilidade e avanço controlados pelo motor. O vídeo é opcional; nunca renomear PNG como MP4.
