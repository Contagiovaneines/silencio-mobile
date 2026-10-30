# 02_primeiro_pulso

## Referências

Anexar os arquivos de assets como referências, não como quadros de colagem. Retratos fixam identidade; sprites fixam roupa e proporção; captura fixa cenário; WAV é guia para pós-produção, não trilha obrigatória. `assets/keyframe_placeholder_v01.png` é o quadro estático que o jogo mostra enquanto o vídeo não existe.

## Prompt pronto

SILÊNCIO: jogo mobile em paisagem, cenário isométrico 2.5D com textura pintada e acabamento pixelizado discreto. Brasil contemporâneo, Santa Aurora. Exteriores azul-petróleo/cinza dessaturados, madeira e luz âmbar nos interiores. Preserve perspectiva, proporções e identidade das referências; não transformar em anime de luta, live-action ou 3D brilhante. Caio tem cabelo preto curto e bagunçado, jaqueta escura, mochila e aparência do retrato fornecido. Caio não fala nem narra. Não inventar diálogos, roupas, poderes, monstros, ferimentos ou acontecimentos. Sem HUD, palavras, legendas, marcas ou logotipos gerados; textos serão aplicados no jogo. Sem flashes repetidos, câmera trêmula, morphing, objetos duplicados ou mudança da planta. As capturas do beta contêm HUD: usar somente cenário e composição como referência, excluir toda a interface do resultado. Nunca gerar vídeo dentro de uma folha de sprites ou colagem.

Cena na rua junto à parada, fim de tarde; não definir modelo de torre nem nova ameaça. 0–1.5s: pedestres distantes continuam seu movimento cotidiano; Caio está consciente. 1.5–2.5s: o ambiente perde gradualmente saturação e o movimento das pessoas cessa, sem explosão e sem estroboscópio. 2.5–4.5s: pessoas imóveis; somente Caio muda discretamente a postura e olha em volta. 4.5–6s: sustentar a inquietação, sem explicar a causa. Usar o sprite de Caio para identidade; não torná-lo super-herói. Não mostrar ônibus transportando Caio: chegar a pé ou de ônibus são opções válidas. Evitar multidão detalhada sem referências. O som grave será aplicado separadamente pelo motor; entregar imagem sem trilha/voz.

Vídeo único de 6 segundos, horizontal 16:9, alvo 1920×1080, 24 fps, sem áudio embutido. Movimento discreto, câmera isométrica coerente. Guardar primeiro e último quadro para conferir continuidade.

## Entrega

Salvar `saida/silencio_f01_pulso_v01.mp4`. MP4 H.264, yuv420p, SDR. Se o serviço exportar outra resolução, manter 16:9 e informar; não esticar a imagem. A taxa e compressão final serão ajustadas na integração. Versões novas usam v02, v03, sem sobrescrever a aprovada.

## Integração

No evento _pulse já existente, depois de canLeave; conclusão ou pular usa a mesma rotina do beta, uma única vez.

O jogo usa atualmente `assets/images/video_placeholder_02_pulso_v01.png` como imagem provisória nesta cena. Ao receber e aprovar o MP4, trocar a mídia deste slot pela reprodução do vídeo e manter texto, acessibilidade e avanço controlados pelo motor. O vídeo é opcional; nunca renomear PNG como MP4.
