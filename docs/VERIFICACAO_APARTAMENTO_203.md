# Verificação — apartamento 203 / versão 0.3

Data: 28/10/2026. Ambiente: Windows, Flutter 3.47.7, navegador do PC, build web release. Sem aparelho Android nesta revisão.

## Resultado automatizado

- `flutter analyze --no-pub`: nenhuma ocorrência.
- `flutter test --no-pub`: 22 testes aprovados.
- `flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run`: concluído.

Os testes incluem chave obrigatória, colisão da porta fechada e borda do segundo andar, abertura/passagem/fechamento nos dois sentidos, navegação até a escada, descida, subida e retorno à cama. Também cobrem migração de saves sem andar, preservação de checkpoint durante transição, percurso da fase e interface em duas dimensões.

## Revisão manual no PC

No navegador: continuar save, pegar chave e adaptador, aproximar-se da porta, sair, alcançar a escada, descer ao térreo, subir e entrar novamente no apartamento. A interface confirmou cada piso. Após recompilar os ajustes finais do recinto da escada e das legendas, recarregar e continuar preservou itens e apartamento 203; movimento interno e arte foram conferidos. Console observado sem erros ou avisos.

Capturas em `screenshots/`: `ap203-porta-fechada.png`, `ap203-corredor.png` e `ap203-terreo.png` registram o percurso antes dos dois ajustes finais. `ap203-final.png` mostra a build final recarregada no apartamento.

## Identificação dos arquivos finais

- `build/web/main.dart.js` SHA-256: `C5033A426109EB73A86F5183E7E6F2A1DBC25C6E63A6935C7DD2EAB0B9219C5C`.
- `assets/images/apartment_furniture_v1.png` SHA-256: `FD4A3E89B862E125B8D22727BDCD1F6873BF50E36AC2A371989D61DA057EDB0F`.

## Limites

O primeiro andar aparece na passagem encenada e não é explorável. O elevador está em manutenção. A arte segue em desenvolvimento, com ciclos existentes de Caio; mão na maçaneta e pisada específica por degrau ainda não têm quadros próprios. Testes no PC não comprovam desempenho, áudio ou controles em um celular. Não foi produzido um novo APK neste lote.
