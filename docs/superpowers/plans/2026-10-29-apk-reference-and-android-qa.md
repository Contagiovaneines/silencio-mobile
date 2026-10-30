# Plano: APKs via REA, integração original e QA Android

## Objetivo

Continuar a análise estática autorizada dos APKs com REA, separar evidências de inferências, escolher uma mecânica que faça sentido para a Fase 01 do SILÊNCIO, implementá-la sem copiar código ou assets e validar a fase no aparelho Android conectado sem apagar o save.

## Checklist de evidência

- [x] Identificar APKs, tamanhos, hashes e inventário REA.
- [x] Instalar REA 6.7.0 em diretório local ignorado, sem mudança global; validar artefato nativo Windows.
- [x] Extrair Mini DAYZ 1 com REA para diretório temporário e conservar Evidence.
- [x] Tentar análise JS estática de `data.js`; registrar falha de parse da exportação JSON do Construct como limite.
- [x] Rodar JADX 0.7.1 após aprovação; registrar evidências individuais dos quatro APKs em `.local`.
- [x] Analisar `data.js` com parser de dados seguro e inventário, sem executar código.
- [x] Revalidar bundles/metadata de Retro Garage, Mini DAYZ 2 e DYSMANTLE; registrar limites por formato.
- [x] Atualizar o relatório com achados verificáveis e separar fatos de inferências.

## Checklist do SILÊNCIO

- [x] Rodar a suíte Flutter completa e análise estática após a alteração de UI.
- [x] Confirmar a Fase 01 automatizada pelo teste de campanha; o catálogo atual não oferece direção veicular completa, e isso ficou registrado como pendência.
- [x] Adicionar regressão de widget para encerrar diálogo de celular sem perder a fase.
- [x] Preservar história, IDs de save e arquivos existentes; o APK Android de teste usou pacote QA isolado.
- [x] Repetir suíte completa, análise estática e build Android após a correção de input modal.
- [x] Instalar com `adb install -r` em `dev.silencio.silencio.qa2` e conferir menu, mundo, celular e fechamento do diálogo no A15.
- [x] Restaurar o arquivo de preferências do pacote QA2 byte a byte (SHA-256 conferido); o pacote de produção e seu save não foram tocados.
- [x] Relatar cobertura física parcial e limites do que REA/JADX conseguiu revelar.

## Resultado desta continuação — 29/10/2026

- REA/JADX examinou estruturalmente quatro APKs; Mini DAYZ 1 também teve inventário seguro do JSON exportado. Nenhum jogo foi executado e não foram extraídos/copied assets ou código.
- A janela de diálogo agora bloqueia input do mundo até o modal fechar. Um teste adicional confirma que concluir a mensagem deixa o jogo em `playing`.
- A suíte completa passou com **133 testes**, e `flutter analyze` reportou `No issues found!`.
- Build debug de QA `0.5.3` / `versionCode 10` foi instalado somente como `dev.silencio.silencio.qa2`. No Samsung A15 foram verificadas a tela principal, o mundo salvo, abertura e fechamento da mensagem de Helena. O percurso inteiro da fase não foi jogado fisicamente.
- A cópia temporária do save de QA2 foi restaurada e seu SHA-256 coincidiu. O app QA2 ficou encerrado após a restauração.
- Os APKs não forneceram lógica que pudesse ser traduzida diretamente para Dart. A janela visual do prédio é um ajuste original do renderer e não uma mecânica derivada desses pacotes.

## Review focus

1. Regressão de save antigo e migração de estado.
2. Colisão e transição do personagem com veículo parado/em uso.
3. Controles touch e HUD em tela pequena.
4. Missão da Fase 01 continua alcançável sem veículo e sem alterar os objetivos do PDF.
5. Renderização não carrega todos os interiores/veículos distantes.

## Fora do escopo concluído / próximos itens

- Decompilar métodos de gameplay Java exige JEB/MCP, que não estava disponível; os arquivos Unity/IL2CPP, nativos e `.pak` não foram decodificados.
- Direção, chave, dano e capotamento de carros; mudanças grandes de cenário; e playthrough integral da Fase 01 no aparelho continuam pendentes.
