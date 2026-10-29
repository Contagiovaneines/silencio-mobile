# Verificação do beta 0.1

Data: 28/10/2026. Flutter 3.47.7 / Dart 3.13.5 / Flame 1.38.2.

## Resultado

- `flutter analyze`: sem problemas.
- `flutter test`: 10 testes passaram. Cobrem salvamento, validação de conteúdo, Caio sem fala vocal, movimento normalizado, colisão, caminho, empurrão, regras de conclusão, ajuda sem duplicação e interface 832 × 384.
- `flutter build apk --debug`: concluído.
- APK instalado e aberto no Samsung SM-A156M, Android 16. Instalação e atualização confirmadas pelo aparelho.
- Conferência visual real: menu, controle e caminhada por toque, conversa com retrato, notícia em três páginas, diário e progresso retomado após atualização.
- Corrigida a oclusão da moradora por prédio: a ordem usa a área ocupada pelo edifício, a posição do ator e a sobreposição projetada, em vez de ordenar tudo pelo canto distante.
- 48 arquivos do pacote do autor copiados; todos os SHA-256 conferem com os originais. Registro em `ASSETS_INTEGRADOS.json`.
- Consulta limitada aos 500 registros mais recentes do Android não encontrou erro fatal, asset ausente ou overflow do Flutter durante a conferência.

## Alcance

A conclusão do trecho foi validada pelas regras automatizadas. A conferência manual no celular não incluiu uma partida completa até o encerramento. O teste não mede bateria, FPS sustentado, aquecimento ou estabilidade em vários aparelhos. Web e iOS não foram compilados nesta entrega.

## Próximas entregas

O beta é um trecho externo original e curto; não contém os 12 capítulos do PDF. Permanecem: interiores, expansão da campanha, áudio, animações de ações, direção E definitiva, inimigos com arte final, consequências mais profundas e testes externos. Veja `ETAPAS.md`.

## APK verificado

SHA-256: `f67de6d2def849655a6c851fe57b35b928e223d4db7bd8c1bfc86a9137bdb3f9`

Compilação de desenvolvimento local. Caminho: `build/app/outputs/flutter-apk/app-debug.apk`.
