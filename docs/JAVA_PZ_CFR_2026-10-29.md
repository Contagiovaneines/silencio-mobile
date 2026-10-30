# Decompilação Java local e aplicação ao SILÊNCIO

## Resultado

A análise de Java foi destravada com CFR 0.152 direto pela CLI, usando Java 21 já instalado. Isso é um caminho alternativo real de decompilação; não é uma reparação do serviço JEB nem uma saída de Evidence REA. Não foi instalado JEB, adquirida licença, alterada configuração global ou iniciado Project Zomboid.

REA local: `C:/Users/giovane/Desktop/editor/rea`. `docs/jeb-analysis.md` exige um cliente JEB próprio servindo MCP. A falha anterior é ausência desse serviço, não corrupção do JAR. Não foi encontrada instalação JEB nos diretórios examinados. A CLI REA permanece utilizável para o inventário anterior; suas operações JEB continuam indisponíveis.

## Entradas e proveniência

- JAR: `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid/projectzomboid.jar`.
- SHA-256: `e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`, igual à investigação anterior.
- Decompilador obtido da [distribuição oficial CFR](https://www.benf.org/other/cfr/): `cfr-0.152.jar`.
- SHA-256 CFR: `f686e8f3ded377d7bc87d216a90e9e9512df4156e75b06c655a16648ae8765b2`.
- Java: `C:/Program Files/Java/jdk-21.0.12/bin/java.exe`, já existente.
- Classes decompiladas: `zombie/iso/IsoCamera.class`, `zombie/iso/IsoObject.class`, `zombie/iso/IsoGridSquare.class`.
- Script reproduzível: `tools/inspect_pz_java.py`. Saída, comandos, hashes por classe e Java gerado: `tools/art/out/java-analysis/provenance.json`.

As três classes produziram arquivos Java com retorno zero. Isso não prova reconstrução perfeita: CFR marca tratamentos de exceção potencialmente diferentes e uma região não totalmente estruturada no renderer de `IsoGridSquare`. A região de flags de corte e os acessores de alpha examinados não apresentam esse aviso. Não recompilar nem redistribuir os fontes comerciais de referência.

## Achados focados

Observações no Java gerado, não inferências do inventário ZIP:

1. `IsoGridSquare` mantém flags de corte por jogador, orientação das paredes e estado desejado separado do estado apresentado. Há retenção temporal em uma das rotas de flags; outra rota de renderização consulta o alvo diretamente. Portanto, não afirmar que todas as versões/caminhos usam o mesmo atraso.
2. `IsoObject` mantém opacidade atual e alvo separadamente, com limites de faixa.
3. O renderer consulta sala/andar, vizinhos e orientação de paredes/janelas para decidir corte e transparência. Telhados não são apenas um retângulo removido independentemente do prédio. A região complexa do renderer tem limitações de reconstrução CFR; não inferir a implementação inteira a partir dela.

Aplicação original: `lib/game/wall_cutaway.dart` usa histerese espacial e aproximação exponencial, com parâmetros próprios. O renderer atualiza cada parede fora do desenho, interpola altura e opacidade das paredes da frente e inicializa o estado imediatamente no carregamento. Não foi copiado código, textura ou algoritmo de flags do PZ. Essa decisão adapta os princípios ao Canvas 2D do SILÊNCIO.

## Repetir

```powershell
python tools/inspect_pz_java.py --jar 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\projectzomboid.jar' --cfr tools/art/out/java-analysis/cfr-0.152.jar --java 'C:\Program Files\Java\jdk-21.0.12\bin\java.exe' --output tools/art/out/java-analysis
```

O script não baixa dependências, executa o jogo ou altera REA. Recusa saída em assets. Os fontes extraídos/decompilados e o decompilador ficam no diretório ignorado de ferramentas e não entram no aplicativo.

## Verificação

- Testes de corte: transição gradual, estabilidade ao oscilar perto da parede, retorno opaco no exterior e inicialização sem um quadro incorreto.
- Testes de renderer: seis cenários e posição das janelas continuam passando.
- Suíte completa: 84 testes passaram; análise estática sem ocorrências.
- Build web release: concluído com retorno zero, saída em `build/web`.
- Logs: `tools/art/out/java-analysis/flutter-test.log`, `flutter-analyze.log` e `flutter-build-web.log`.
- Android e aparência em partida manual ainda exigem validação; renderização offline não substitui esses testes.
