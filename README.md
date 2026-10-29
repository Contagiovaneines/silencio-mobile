# Silêncio — fase 01 / versão 0.4.1

Jogo original de investigação e sobrevivência leve em Flutter + Flame. Versão Android 0.4.1 instalada no Samsung Galaxy A15 em paisagem. A revisão reaproveita ideias e duas ilustrações da primeira tentativa em Godot: [reuso e verificações](docs/REUSO_PRIMEIRA_VERSAO.md). A revisão anterior do prédio permanece em [verificação do prédio e Android](docs/VERIFICACAO_PREDIO_04.md).

## Jogar no Android

O aplicativo instalado chama-se Silêncio. O APK atual está em `build/releases/silencio-0.4.1-android.apk`; é uma versão de desenvolvimento assinada com a chave de teste existente. A atualização foi feita com preservação dos dados, sem desinstalar ou limpar o aplicativo. O save antigo v1 continua preservado; a campanha atual utiliza o slot v2.

O menu inclui Configurações e Jornada. A Jornada mostra os doze espaços de capítulo, mas somente a fase 01 está jogável; os demais estão em produção. O mapa local continua disponível durante a exploração. O prólogo usa quadros ilustrados, leitura manual por padrão, Anterior/Avançar/Pular e avanço automático opcional. Reassistir não reinicia a campanha.

## Jogar no PC

Abra `JOGAR_NO_PC.cmd` nesta pasta. Ele usa o Flutter já instalado neste computador e abre o Chrome. Mantenha a janela do comando aberta enquanto joga.

No VS Code, abra a pasta inteira `C:/Users/giovane/Desktop/editor/silencio`, escolha a configuração Chrome e pressione F5. Pelo terminal:

```powershell
flutter pub get
flutter run -d chrome
```

A versão web de teste também está em `build/web`. Sirva essa pasta por HTTP; não abra o index.html diretamente como arquivo. A prévia atual usa `http://127.0.0.1:58402`. A origem anterior 58401 foi preservada com seu progresso; pode manter recursos antigos no cache do navegador.

## Apartamento 203 e andares

Caio mora no segundo andar. Pegue a chave, aproxime-se da porta 203 e use E / Abrir e passar. No corredor, desça ao primeiro andar, depois ao térreo. A entrada residencial conecta o hall à calçada; o caminho inverso funciona pelos dois lances. Dona Inês fica perto do 202. Unidades 201/202 e 101/102/103 têm áreas separadas e portas fechadas nesta fase. O elevador continua em manutenção.

A porta abre, Caio atravessa e ela fecha. A escada tem descida/subida encenada e transição curta por lance, com os três pisos preparados em memória. A planta compartilhada define as divisórias, aberturas, corredores e posições das portas na fachada. [Detalhes atuais](docs/PREDIO_04.md).

O 203 tem banheiro separado com porta própria, pia, vaso e chuveiro. Aproxime-se de cama, sofá, cadeira, armário, geladeira ou notebook e use a ação contextual. Os painéis permitem levantar/fechar. O armário guarda e devolve ataduras; a água da geladeira é consumida uma vez; o notebook apresenta o caderno existente. Descansar não avança os marcos da missão.

## Controles

- WASD ou setas: caminhar. R: alternar corrida.
- Mouse/toque no chão: caminhar até o ponto por caminho válido.
- E: interação próxima; Espaço: empurrão com antecipação e contato; Q: Percepção.
- P: celular; M: mapa; J: diário; Esc: pausa/voltar; Enter: avançar fala.
- Atadura no HUD: tratar ferimento em segurança. Os botões de toque continuam disponíveis.
- Pausa: sons, efeitos reduzidos e texto maior; preferências persistem.

## Percurso da primeira fase

Abertura pulável → apartamento 07:12 → celular, chave e adaptador → porta 203 → corredor/Dona Inês → escada → térreo/garagem/Fubá → mercearia de Orlando → notícia e tomada → praça/Breu/Pingo → crise de Davi → portão ou distância → ônibus opcional ou passagem a pé → primeiro pulso → mensagem de Helena → retorno ao apartamento e cama.

A mercearia e o apartamento têm entradas ao sul. Helena participa por mensagens. O sedã só permite pegar a atadura após Orlando autorizar. Davi deve ser separado, não morto. A fase só termina depois do retorno para casa.

## Implementação disponível

- Cenário conectado com interiores recortados, edifícios, mobiliário, sedã, van e ônibus.
- Colisão nos pés com paredes, móveis, carros, pessoas e Fubá. O caminho automático valida também os segmentos entre células.
- Caio com idle por direção, caminhada/corrida por deslocamento real e poses de empurrão, impacto, coleta, cura e derrota.
- Fubá circula na garagem; Breu observa da janela; Pingo tem reação simples.
- Encontro com aviso antes do golpe, distância, linha livre e recuperação; cura consome atadura no contato.
- Mapa, caderno, histórico, retratos, notícia em três páginas, abertura e encerramento.
- Chuva e 13 sinais/efeitos WAV originais de protótipo. Sem voz de Caio. Silenciar e sair do aplicativo interrompem o ambiente.
- Checkpoint seguro, salvamento local, coleta idempotente e retomada após derrota.

## Plano e arte pendente

Pacote de mídia futura: [prompt/README.md](prompt/README.md), com quatro prompts de vídeo e cinco de animação interativa, referências por pasta e destinos de entrega. [Mundo e interações](docs/MUNDO_E_INTERACOES.md) registra a proposta de exploração opcional e ações domésticas; são planejamento, ainda não novas mecânicas do beta.

[Plano da fase 01](docs/FASE_01_PLANO.md) · [Matriz de animações](docs/ANIMACOES_FASE_01.md) · [Áudio](docs/AUDIO.md).

Esta é uma fase de desenvolvimento, com narrativa e ações implementadas. Ainda exige acabamento artístico: NPCs e Davi não têm ciclos finais completos; algumas vistas de Caio são espelhadas; paredes e abertura usam desenho no motor, com móveis originais em PNG; animais não têm oito direções nem voo final; ônibus usa transporte curto roteirizado. Não há direção livre de veículos, armas de fogo, multiplayer ou os demais capítulos.

O APK debug 0.1 em `build` é histórico. O APK release 0.4 é o arquivo atual. A revisão no Galaxy A15 não substitui testes prolongados de aquecimento nem testes em outros aparelhos; áudio e balanceamento continuam sujeitos à revisão de experiência.

## Dados e preservação

O PDF fica na raiz. `docs/roteiro-extraido.txt` é uma cópia textual para consulta. O pacote original de assets em Documents foi preservado; `docs/ASSETS_INTEGRADOS.json` registra cópias e hashes. Nenhum código ou asset dos jogos de referência foi incorporado.

O save atual usa `silencio.campaign.v2`; o progresso antigo `v1` permanece guardado, pois o percurso mudou. Uma cópia das fontes do beta anterior está em `docs/backups/beta-0.1-fontes.zip`.

## Verificações

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
```

Consulte `docs/VERIFICACAO_APARTAMENTO_203.md` para a revisão atual. `docs/VERIFICACAO_FASE_01_PC.md` preserva o registro anterior. O registro do beta 0.1 permanece separado.

## Estrutura

`lib/models` contém o estado persistente; `lib/game` contém simulação, direção de sprites e renderização; `lib/ui` contém menus e painéis; `lib/services` contém save e áudio. A história está em `assets/data/chapter_01.json`; `phase_assets.json` lista os recursos adicionais.

Documentação técnica: [Flutter para jogos](https://flutter.dev/games), [Flame](https://docs.flame-engine.org/latest/), [áudio](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html).
