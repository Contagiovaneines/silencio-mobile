# 01_abertura

## Referências

Anexar os arquivos de assets como referências, não como quadros de colagem. Retratos fixam identidade; sprites fixam roupa e proporção; captura fixa cenário; WAV é guia para pós-produção, não trilha obrigatória. `assets/keyframe_placeholder_v01.png` é o quadro estático que o jogo mostra enquanto o vídeo não existe.

## Prompt pronto

SILÊNCIO: jogo mobile em paisagem, cenário isométrico 2.5D com textura pintada e acabamento pixelizado discreto. Brasil contemporâneo, Santa Aurora. Exteriores azul-petróleo/cinza dessaturados, madeira e luz âmbar nos interiores. Preserve perspectiva, proporções e identidade das referências; não transformar em anime de luta, live-action ou 3D brilhante. Caio tem cabelo preto curto e bagunçado, jaqueta escura, mochila e aparência do retrato fornecido. Caio não fala nem narra. Não inventar diálogos, roupas, poderes, monstros, ferimentos ou acontecimentos. Sem HUD, palavras, legendas, marcas ou logotipos gerados; textos serão aplicados no jogo. Sem flashes repetidos, câmera trêmula, morphing, objetos duplicados ou mudança da planta. As capturas do beta contêm HUD: usar somente cenário e composição como referência, excluir toda a interface do resultado. Nunca gerar vídeo dentro de uma folha de sprites ou colagem.

Plano de estabelecimento da cidade numa manhã chuvosa comum. 0–2s: rua e poças, janelas quentes do prédio. 2–6s: deslocamento de câmera muito lento em direção ao prédio; chuva suave e cotidiano discreto, sem revelar ameaça. 6–8s: estabilizar o enquadramento numa janela do segundo andar, mantendo geometria consistente. Não atravessar a parede nem mostrar Caio teleportando. A continuação será um corte feito pelo motor para o apartamento. A imagem conceito da cidade é direção artística, não planta final nem lugar novo canônico.

Vídeo único de 8 segundos, horizontal 16:9, alvo 1920×1080, 24 fps, sem áudio embutido. Movimento discreto, câmera isométrica coerente. Guardar primeiro e último quadro para conferir continuidade.

## Entrega

Salvar `saida/silencio_f01_abertura_v01.mp4`. MP4 H.264, yuv420p, SDR. Se o serviço exportar outra resolução, manter 16:9 e informar; não esticar a imagem. A taxa e compressão final serão ajustadas na integração. Versões novas usam v02, v03, sem sobrescrever a aprovada.

## Integração

Antes da abertura atual; pular leva ao apartamento 203, 07:12, sem marcar objetivos.

O jogo usa atualmente `assets/images/video_placeholder_01_abertura_v01.png` como imagem provisória nesta cena. Ao receber e aprovar o MP4, trocar a mídia deste slot pela reprodução do vídeo e manter texto, acessibilidade e avanço controlados pelo motor. O vídeo é opcional; nunca renomear PNG como MP4.
