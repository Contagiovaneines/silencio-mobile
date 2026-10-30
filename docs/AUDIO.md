# Áudio do SILÊNCIO — revisão de 29/10/2026

Os bipes de animais e a chuva de ruído branco foram substituídos por gravações públicas do Freesound com licença CC0 conferida na página de cada autor. Também foram substituídos passo e porta; janela e sopro do golpe agora têm arquivos correspondentes aos eventos emitidos pelo jogo.

| Evento | Gravação / autor | Licença |
|---|---|---|
| Gato | [cat meow — tuberatanka](https://freesound.org/people/tuberatanka/sounds/110011/) | CC0 |
| Cachorro | [dogbark.wav — ipears1](https://freesound.org/people/ipears1/sounds/118072/) | CC0 |
| Pombo | [Pigeon — JavierSerrat](https://freesound.org/people/JavierSerrat/sounds/524345/) | CC0 |
| Chuva | [Soft rain.WAV — barkenov](https://freesound.org/people/barkenov/sounds/640655/) | CC0 |
| Porta | [dorm door opening.wav — pagancow](https://freesound.org/people/pagancow/sounds/15419/) | CC0 |
| Passo | [Single Footstep — ZNukem](https://freesound.org/people/ZNukem/sounds/697182/) | CC0 |
| Janela | [WINDOW OPENING — SamuelGremaud](https://freesound.org/people/SamuelGremaud/sounds/437636/) | CC0 |
| Sopro do golpe | Síntese original SILÊNCIO, sem voz | Original do projeto |

Foram utilizados os previews HQ públicos, não os originais restritos ao download autenticado. A extensão do navegador informou `Local browser use is disabled in Work settings`; não foi acessada a sessão logada, alterada a configuração do navegador ou extraído cookie/token.

## Processamento e reprodução

- WAV PCM mono, 16 bits, 22.050 Hz. Efeitos curtos, sem silêncios iniciais longos; filtro e fades nas pontas. Fontes em MP3 não recuperam qualidade ao serem convertidas para WAV.
- Pico das gravações limitado a aproximadamente -4 dBFS; volume final próprio por evento. Passos abaixo dos impactos; animais com intervalo mínimo e no máximo uma instância simultânea por tipo.
- Chuva de 23,25 segundos com sobreposição na emenda do loop; mais baixa dentro do prédio. Música/ambiente e efeitos preservam as opções existentes.
- Sem voz de Caio. Sons são apresentação para o jogador e não substituem as pistas visuais ou mudam o que o personagem sabe.
- Os demais efeitos estilizados de interface, impacto, empurrão, cura, motor e pulso continuam sendo originais do protótipo.

## Fontes e reconstrução

`tools/audio_sources.py` baixa as páginas e previews públicos, exige CC0, processa candidatos fora dos assets e registra URLs/hashes em `tools/art/out/audio-review/sources.json`. Metadados das gravações instaladas em `assets/data/audio_sources.json`. Originais substituídos preservados em `tools/art/out/audio-review/originals/`.

O gerador antigo `tools/generate_audio.py` recusa sobrescrever o pacote de gravações por padrão; `--replace-recordings` restaura explicitamente os sons de protótipo. Não usar essa opção para reconstruir o pacote atual.

`python tools/verify_audio.py` verifica os 16 WAVs: formato, sinal não vazio, pico sem clipping, componente DC e emenda da chuva. Relatório em `tools/art/out/audio-review/signal-check.json`. A verificação de sinal não equivale a audição manual em aparelho; essa avaliação continua necessária.

Verificação desta revisão: 87 testes passaram em execução sequencial (`flutter test --concurrency=1 --reporter expanded`), incluindo os três testes novos de áudio. Uma execução concorrente anterior teve timeout no teste de renderização do apartamento; a repetição sequencial completa passou. `flutter analyze --no-pub` sem ocorrências e build web release concluído com retorno zero. Logs completos em `tools/art/out/audio-review/`. Os hashes das sete gravações instaladas conferem com a proveniência, e o bloqueio do gerador antigo foi verificado sem alterar os 16 WAVs.
