# Poses domésticas originais

Arquivo: `assets/images/caio_home_poses_v1.png`, RGBA 2172×724. Gerado com imagegen integrado em 28/10/2026 a partir de `pose_SE_idle.png` e `portrait_caio.png`. Os originais foram preservados. Não foi extraído de jogo de referência nem editado por script.

SHA-256: `790f5d1e9c90e9a607b448e75cf0df234f31ff69295a3360b24d7728b0cf6c4e`.

Quatro estados: sentado, deitado/reclinado, sentado digitando e alcance em pé. A folha foi inspecionada; não corresponde a quatro células quadradas perfeitas. Os retângulos em `assets/data/caio_home_poses.json` foram determinados pela ocupação alfa e são usados diretamente no renderer. As proporções de apresentação são ajustadas por estado; âncoras visuais não movem o corpo físico de Caio para dentro do colisor do móvel.

Prompt utilizado:

Create an original game animation reference sprite atlas of this exact character Caio from SILENCIO. Transparent RGBA background. Black messy short hair, dark jacket, dark trousers, brown shoes and backpack same as reference. Maintain painted pixel art isometric three-quarter view facing southeast. EXACTLY four isolated full-body sprites in one horizontal row of four equal square cells, no overlap, feet and head contained well within each cell. Cell1 seated on an invisible chair, natural bent legs, visible feet; Cell2 lying on his back on an invisible bed, head at upper-right and feet lower-left consistent isometric ground plane, not a standing sprite simply rotated; Cell3 seated typing at an invisible desk, hands forward, natural bent legs; Cell4 standing reaching forward with right hand to open an invisible cupboard. No furniture, no floor, no shadows outside sprite, no words numbers borders guides labels logos. Character same scale across seated/standing poses; lying body must fit inside its own cell. Each cell separated by generous transparent margin. This is functional game sprite artwork, not a storyboard.

O resultado é uma revisão de poses, não ciclos completos de entrada/saída. A pose de repouso ainda inclui a mochila; uma versão final para dormir deve removê-la e mostrar onde foi colocada, sem alterar a identidade ou inventário do personagem.
