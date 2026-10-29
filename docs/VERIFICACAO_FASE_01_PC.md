# Verificação da fase 01 no PC — 0.2.0

Data: 28/10/2026. Flutter 3.47.7, Dart 3.13.5, Flame 1.38.2 e flame_audio 2.12.2. Celular indisponível a pedido do usuário; nenhuma operação no aparelho nesta revisão.

## Verificação automatizada

- `flutter analyze`: sem problemas.
- `flutter test`: 17 testes passaram.
- `flutter build web --release --no-web-resources-cdn --no-wasm-dry-run`: concluído. Recursos do renderizador incluídos localmente.
- Assets: 192 arquivos copiados do pacote do autor, hashes preservados; 144 entradas adicionais no manifesto da fase; todos os recursos previstos presentes no pacote web.
- Áudio: 14 WAVs mono de 16 bits e 22.050 Hz, não vazios, verificados e incluídos.

Cobertura: progresso e validação de save, fala não vocal de Caio, sequência obrigatória do capítulo e retorno à cama, loot autorizado sem duplicação após load, checkpoint e derrota, pausa de perigo durante leitura, movimento normalizado, orientação, colisão com pessoa/parede/veículo, percurso completo pelos pontos interativos sem colisão, empurrão com atraso de contato, ataque bloqueado por portão e com aviso, cura idempotente, mapeamento distinto de caminhada/corrida e UI com teclado em 832 × 384 e 1366 × 768.

O teste de eventos do capítulo posiciona o jogador perto das interações para testar suas transições. Um teste separado percorre os caminhos reais do mapa, validando colisão em cada passo. Esses resultados não são uma partida manual completa.

## Conferência no navegador

Servidor HTTP limitado a 127.0.0.1:58401. Aberto no navegador Chromium do Codex no PC.

Conferidos: menu, abertura, retomada, conversa e retratos, avanço das três mensagens, mapa pelo atalho M, fechamento pelo Esc, caminhada pela tecla D, pausa pelo Esc e orientação mantida ao parar. Um erro em que GameWidget consumia o teclado antes da interface foi corrigido; o componente deixou de disputar o foco.

Também corrigidos: busca de caminho cruzando paredes finas; cache de imagens compartilhando carregamentos pendentes entre instâncias; quadro de opções sem superfície Material; direção de corrida diferente dos rótulos de caminhada; fontes dos controles adaptativos ausentes no pacote.

## Limites

Não houve nova validação Android, iOS, bateria, aquecimento ou distribuição em loja. O áudio foi validado como recurso e integração, sem uma avaliação auditiva humana final. O capítulo inteiro não foi concluído manualmente no navegador nesta conferência. A arte é de desenvolvimento: ver `ANIMACOES_FASE_01.md` e `FASE_01_PLANO.md` para ciclos finais, veículos, animais e cenários ainda pendentes.

## Identidade da compilação

SHA-256 de `build/web/main.dart.js`: `c52360b8ffcb42675b399e871ef1e4883d2dc97f444abf8024ad5d236e80795c`.

O APK do beta anterior não representa esta compilação para PC.

Prévias reais desta compilação: `screenshots/pc-fase-01.png` e `screenshots/pc-mapa-01.png`. Na última leitura do console do navegador não foram encontrados erros ou avisos capturados.
