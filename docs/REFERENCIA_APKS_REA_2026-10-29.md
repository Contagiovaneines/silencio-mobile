# Inventário REA dos APKs de referência — 2026-10-29

## Escopo e resultado

Foi feita inspeção estática dos quatro APKs com REA 6.7.0. O provider JADX 0.7.1 foi baixado após autorização, guardado em `.local` (ignorado pelo Git) e validado pelo SHA-256 oficial fixado no REA. O provider carregou os quatro APKs e decodificou seus manifestos e metadados DEX. Isso não executa os jogos nem revela automaticamente a lógica principal quando ela está em JavaScript, Unity/IL2CPP ou biblioteca nativa.

O Mini DAYZ 1 também foi extraído com REA e sua exportação `data.js` foi lida como JSON de dados (sem executar JavaScript). A consulta do REA registrou 1.088 classes DEX, mas não foi feita decompilação de métodos de gameplay; nos quatro pacotes a rota de métodos só seria útil para wrappers Android e bibliotecas. O serviço JEB/MCP continua indisponível. Portanto, não afirmo ter observado ou validado em execução a física, animações, combate, direção ou comportamento de NPCs dos jogos.

## Pacotes examinados

| APK | Tamanho | SHA-256 | Evidência REA | Cobertura |
|---|---:|---|---|---|
| `mini-dayz-1-4-1.apk` | 40.849.855 bytes | `49d945eb474d7b8c2e708665a16dae0871f8bf9f74c65f63e26c243d7eec4671` | `ev_a7cc58703b44fdf7939ac0a657c78e1d219208e14b38fe1c13eb751ebbfa0efd` | 1.088 classes DEX, 1.568 recursos |
| `mini-dayz-2-1-3-2.apk` | 147.090.916 bytes | `b25cacc4e1ce131a0dfeb1f50a8536929e1bfc5be0fd3c2b7b3faa301db6fc0d` | `ev_44de7e44d8c2f6d90f89180dc3ac42398117699baf477f4a01010d2b3e327022` | 3.705 classes DEX, 6.027 recursos |
| `retro-garage-3-1-0.apk` | 125.350.656 bytes | `cfafd66b4f08ffa6b2c7f168b4dbf8ef8ff84ab30079a67c094596dd1047e2eb` | `ev_9b73e77449a60e5ce95c64d02de8326cfb579b09128060c5376ede078bfd7e23` | 14.646 classes DEX, 1.422 recursos |
| `dysmantle-1-0-4-24.apk` | 505.504.575 bytes | `b3094599d4819b25fc28bc58c1088f6f946ebe611ffe201843580acbc14740a2` | `ev_50c33cf3f55c71fe8b151b5a6b191fc37268965bd6ed2543e142866473efdb87` | 642 classes DEX, 356 recursos |

As evidências JSON completas estão no diretório local ignorado pelo Git `C:\Users\giovane\Desktop\editor\rea\.local\apk-research\`. Cada inventário registra a limitação de cobrir apenas entradas no diretório central; bytes fora dele, como APK Signing Block e comentário ZIP, não estão representados.

## Observações verificadas e limites

### Mini DAYZ (1.4.1)

- O APK contém `assets/www/c2runtime.js`, `assets/www/data.js`, `assets/www/config.json`, `cordova.js`, e arquivos com nomes como `ground_enviroment_tilemap.png`, `ground_lvl1_tilemap.png` a `ground_lvl4_tilemap.png`, `tilemap_bunker.png` e `tilemap_bunker_collision.png`.
- A presença de `c2runtime.js` e da estrutura Cordova sugere um runtime baseado em Construct 2/Cordova. Isso é uma inferência estrutural, não verificação da engine em execução.
- Os nomes dos recursos indicam mapas/tiles e um recurso separado de colisão; não comprovam a regra de navegação nem a qualidade da jogabilidade.
- A leitura segura do JSON exportado encontrou 29 entradas principais, 7 layouts (incluindo mapa 17.850×20.000, tutorial e menu), 6 event sheets, 947 definições de objetos e 415 entradas de mídia. Nomes de estados/eventos incluem `Day_mode`, `Day_Night_speed`, `Rain`, `Player_temperature`, `Death_log_*`, `Bot_corpse_stay_time`, `ZED_RESPAWN_TIME`, itens, armas e variantes de corrida em superfícies. Esses nomes confirmam que o projeto exportado contém dados para esses sistemas; não determinam todos os seus algoritmos nem demonstram o resultado em execução.
- A inspeção dos valores declarados registra `Day_mode=1`, `Day_Night_speed=720`, `Rain_speed=360`, `Bot_corpse_stay_time=90`, `BOT_RESPAWN_TIME=10`, `ZED_RESPAWN_TIME=60`, `Zed_fast_dmg=6`, `Zed_dmg=9` e `Zed_army_dmg=13`. São valores iniciais encontrados no arquivo, sem unidades ou semântica de tempo confirmadas. Não os repliquei no SILÊNCIO nem tratei os nomes como prova de uma implementação funcional.

### Mini DAYZ 2 (2.1.3.2)

- O pacote possui `assets/bin/Data/Managed/Metadata/global-metadata.dat`, `globalgamemanagers.assets`, cenas `level0`–`level20` e diversos arquivos `.assets`/`.resource`.
- A estrutura é compatível com um empacotamento Unity, possivelmente IL2CPP. A inspeção JADX confirmou metadados DEX, mas não determinou engine, classes de gameplay ou uso dos assets.

### Retro Garage (3.1.0)

- Foram vistos `assets/aa/AddressablesLink/link.xml`, bundles sob `assets/aa/Android/` e grupos com nomes como `common_assets_all`, `drive-cars_assets_car-audi100_*`, `drive-cars_assets_car-bmw30_*`, `drive-cars_assets_car-gaz*` e `azlk*`.
- A organização sugere conteúdo de veículos separado em bundles Addressables. Isso pode inspirar uma organização modular de carros no SILÊNCIO; **não confirma** direção, reparo, chaves, dano ou customização no jogo de referência.

### DYSMANTLE (1.0.4.24)

- O APK contém pacotes grandes `assets/data.pak`, `data-localizations.pak`, `data-1200p.pak`, `manifest-data.xml` e uma biblioteca nativa `lib/armeabi-v7a/libNativeGame.so`.
- O inventário confirma empacotamento de dados e componente nativo, mas não explica seus formatos internos nem permite inferir mecânicas. O conteúdo desses pacotes não foi extraído.

### Inspeção Android/JADX

- Manifestos e contagens acima foram observados pelo REA/JADX 0.7.1; assinatura dos APKs não foi verificada e nenhum app foi executado por essa ferramenta.
- O uso de wrappers Java não expõe por si só lógica de gameplay. Em especial, a presença de dados Unity/IL2CPP ou bibliotecas nativas limita a extração Java, e os arquivos `data.pak`/bundles não foram convertidos em sprites para o SILÊNCIO.
- Evidências adicionais de busca de classes e saídas completas estão em `C:\Users\giovane\Desktop\editor\rea\.local\apk-research\` (cache local, não versionado).

## Aplicação original possível ao SILÊNCIO

Estas são propostas de arquitetura para implementar arte e comportamento próprios; não são alegações sobre o funcionamento interno dos APKs:

1. **Mapa e colisão:** organizar cada região como tiles/células com camadas próprias de chão, detalhes, construções, objetos, colisão e objetos interativos. Validar que a colisão bloqueia paredes e móveis mesmo quando a parede fica oculta pela câmera.
2. **Veículos:** separar definição do veículo, estado persistente e apresentação visual. Estados de design possíveis: estacionado, trancado, avariado, utilizável e abandonado; dirigir dependeria de chave e condição funcional. Carros, peças e variações visuais devem ser assets originais.
3. **Conteúdo expansível:** separar mapas e conjuntos de assets por região e carregar apenas o entorno ativo, mantendo identificadores estáveis para salvar objetos e progresso.
4. **Arte:** recriar sprites originais com escala e pivô coerentes com os assets existentes. Não recortar nem reutilizar imagens, áudio, modelos, texto ou código dos APKs.

O padrão de arte e integração deve seguir `C:\Users\giovane\Desktop\editor\silencio\.agents\skills\pxl-pixel-art\SKILL.md` e `pixel-art-game-studio\SKILL.md`. Para a sensação de movimento/impacto, consultar `game-feel`; essas skills guiam a produção e a validação do conteúdo próprio, não revelam a implementação dos APKs.

## O que ainda precisa para responder sobre mecânicas

- Código, classes e referências Android dos APKs: requer que a rota `inspect_android_package` do REA funcione com os controles Windows suportados, ou ambiente Linux configurado conforme o guia oficial do projeto REA. Não foi tentado instalar engines ou decompiladores externos.
- Fluxos reais de gameplay: requer execução observável dos jogos ou documentação confiável. Inventário estático não substitui essa validação.
- A afirmação de que os APKs são projetos anteriores do usuário foi registrada como contexto fornecido pelo usuário; a inspeção não valida autoria ou licença. Mesmo assim, o projeto SILÊNCIO determina que não se copiem diretamente código ou assets comerciais.

## Integração/QA do SILÊNCIO nesta continuação

- A fachada simplificada mostrada no modo de corte interno ganhou janelas com vidro e caixilho em vez dos antigos traços diagonais em X. É arte geométrica original gerada pelo renderer; nada foi extraído dos APKs.
- A suíte automatizada e a análise estática foram repetidas após o ajuste de renderização e input: **133 testes aprovados** e `flutter analyze` sem problemas. A janela inferior da fachada agora desenha vidro e caixilho; isso melhora a leitura visual, mas não resolve por si só o volume externo que ainda ocupa a vista de corte.
- Capturas REA do celular já confirmaram menu, sequência de abertura e entrada no apartamento; a captura mostrou a antiga fachada com janelas em X, que motivou a substituição. Isso não equivale a uma conclusão da Fase 01 em aparelho físico.
- O APK debug `0.5.3` (código 10) foi instalado no pacote separado `dev.silencio.silencio.qa2`; o app de produção `dev.silencio.silencio` não foi atualizado. No Samsung A15 foram conferidos o menu, o mundo salvo e abrir/avançar/fechar a mensagem de Helena. O percurso completo não foi jogado no aparelho.
- A mensagem modal bloqueia agora input de fundo; foi incluído um teste de regressão de widget. O save isolado do QA2 foi restaurado e o SHA-256 do XML restaurado coincide com o backup anterior ao teste.
