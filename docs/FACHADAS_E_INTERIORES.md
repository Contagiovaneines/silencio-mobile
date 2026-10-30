# Fachadas e interiores

Pedido: ver a fachada e entrada dos locais por fora; ao entrar, ver o interior correspondente.

A mercearia agora tem fachada opaca, vitrines, placa, moldura da entrada e cobertura. A abertura está em x=28, y=24, com a mesma largura de passagem da geometria existente. A porta comercial permanece aberta: atravessar a entrada revela a loja sem teletransporte, botão adicional ou alteração do save. Não foi adicionado um estado fictício de fechadura.

Quando Caio está fora, móveis e personagens internos ficam ocultos pela loja. Ao entrar, aparece o interior com paredes de fundo altas, frente baixa e cobertura cortada; a rua continua no cenário. Ao sair, a fachada/cobertura retornam. Marcadores de objetos internos também não aparecem sobre a fachada.

O apartamento mantém a mesma regra já existente: no corredor, unidade fechada e entrada; no cômodo ocupado, interior recortado; na rua, fachada do edifício. A mercearia passou a seguir essa apresentação em vez de permanecer exposta por dentro o tempo todo.

Colisão e apresentação são independentes. Ocultar uma estante não remove seu obstáculo: o catálogo físico de móveis é consultado por andar, mesmo fora da loja. Áudio ambiente usa o estado interno da loja para reduzir a chuva.

Verificação: teste de entrada física pelo vão, conteúdo oculto fora/visível dentro e colisão da estante invariável. O percurso completo da fase continuou passando. Capturas do renderer real em `tools/art/out/world-review/street-current.png`, `shop-inside-current.png`, `corridor-current.png` e `apartment-current.png`; essas capturas são offline, não testes manuais em Android.

Resultado final: 89 testes passaram com concorrência 2, análise estática sem ocorrências e build web release concluído com retorno zero. Logs `storefront-full-test.log`, `storefront-analyze.log` e `storefront-build.log` no diretório das capturas. História e formato dos saves preservados; Android não foi testado nesta revisão.
