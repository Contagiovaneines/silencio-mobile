# Continuidade do mundo e contato dos pés

Pedido: corrigir cenário, prédios, NPCs e caminhada com a referência visual enviada em 29/10. Implementação original sobre Flutter/Flame; preservar mudanças existentes e saves.

Decisão: manter coordenadas e colisões atuais. Exibir rua abaixo do andar ocupado, laje com espessura, corredor conectado e volumes fechados das unidades não ocupadas. Cortar somente as paredes que escondem o jogador. Não isolar o apartamento em fundo vazio.

Alternativas: trocar o motor exigiria refazer campanha e saves; trocar apenas texturas conservaria o defeito estrutural. Corrigir composição, geometria e pivôs no renderer atende ao pedido existente.

- [x] Capturar interior, corredor, térreo e rua com o renderer real; antes/depois do apartamento.
- [x] Corrigir chão contínuo, contexto externo e laje sem alterar colisores.
- [x] Manter apartamentos vizinhos fechados, paredes e portas alinhadas ao chão.
- [x] Renderizar os quadros de Caio inteiros, com contato dos pés em y=119 do atlas de 128px.
- [x] Revisar NPCs e escala de móveis pelo mesmo chão; passada na direção projetada. Novos ciclos de NPC em oito direções permanecem pendentes.
- [x] Inventariar os nove mods, ler implementações relevantes e registrar aplicações e limites em MODS_ZOMBOID_2026-10-29.md.
- [x] Verificar REA/JEB (indisponível), 81 testes de percurso/saves/renderização, análise estática sem ocorrências e build web.

REA: CLI 6.5.0 disponível em cache; list-jeb-units retornou capability_unavailable em 29/10. Não há decompilação Java nesta etapa. Não copiar código/assets comerciais ou de mods para o aplicativo.
