# Ferramentas de arte do SILÊNCIO

## Padrão de autoria: claude-pxl

O fluxo local está instalado em `.agents/skills/pxl-pixel-art` a partir do repositório público [`crsolver/claude-pxl`](https://github.com/crsolver/claude-pxl), commit `21fee41f7ecce00bc868d7567f24ffd0f3acc8fa`. O repositório declara licença MIT. A skill ensina desenhar sprites, tiles e animações em `.px.js`, gerar prévias e exportar PNGs/folhas de sprites. O jogo só inclui os PNGs revisados; Node/pxl não entram no APK.

Comando do projeto (Node empacotado do Codex, v24.22.1):

```powershell
& 'C:\Users\giovane\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' `
  '.agents/skills/pxl-pixel-art/bin/pxl.js' build tools/art/concrete_floor.px.js
```

As fontes editáveis ficam em `tools/art/`; as prévias geradas ficam em `tools/art/out/` (ignorado pelo Git). Para o Flutter, somente exports aprovados devem ficar em `assets/`. O primeiro conjunto gerado por esse fluxo contém quatro tiles de concreto 64×32; as marcas são leves e associadas a juntas, umidade, trincas e pequenos detritos.

## perfectPixel

[`theamusing/perfectPixel`](https://github.com/theamusing/perfectPixel) detecta uma grade e realinha imagens pixeladas estáticas via Python/NumPy, com OpenCV opcional. Ele não gera animações nem corrige o ciclo de caminhada, então não foi instalado como dependência nem aplicado aos sprites existentes. O README/pyproject declara MIT, mas o repositório consultado não contém arquivo `LICENSE`; se for necessário para uma arte parada, testar em cópia e verificar a licença antes de incorporá-lo ao fluxo.

## Outras referências

- [Watabou](https://watabou.github.io/) é referência para rascunhos de plantas/mapas; os exports precisam ser convertidos em geometria e objetos do mundo SILÊNCIO, não usados como imagem de fundo.
- [KitBitz](https://kitbitz.art/) pode fornecer objetos quando a licença individual do item for adequada.
- [Clembod](https://clembod.itch.io/) e [Pxl Lab](https://www.pixellab.ai/) são referências/serviços externos para produção de arte. Confirmar a licença do pacote gerado e adaptar perspectiva, escala e pivô antes de integrar.
- `perfectPixel` deve ser usado apenas como pós-processador offline em arte estática; nunca em uma sequência de quadros sem análise comparativa de todos os frames.

## Veículos direcionais

Os sprites de quatro vistas para sedã, van e ônibus foram gerados para SILÊNCIO a partir dos veículos já usados no jogo; não reutilizam arquivos de terceiros. As fontes atlas transparentes ficam em `tools/art/source/vehicle_atlases/`. `python tools/split_vehicle_atlases.py` exporta os recortes PNG usados pelo Flutter em `assets/images/`: frente esquerda, frente direita, lateral e traseira em três quartos para cada veículo. O script só recorta a região alfa, sem redimensionar ou retocar pixels. A lista runtime fica em `assets/data/phase_assets.json`.

## Louças do apartamento

O atlas transparente `tools/art/source/bathroom_fixtures/fixtures.png` contém três sprites originais para o banheiro (vaso, gabinete com pia/espelho e box). `python tools/split_bathroom_atlas.py` recorta as regiões alfa em PNGs individuais para `assets/images/`, referenciados em `assets/data/phase_assets.json`. O atlas é uma fonte de edição; o jogo carrega apenas os três recortes.
