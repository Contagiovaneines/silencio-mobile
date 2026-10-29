# Matriz de animações da fase 01

| Entidade/estado | Implementação | Pendência artística |
|---|---|---|
| Caio parado | pose por direção revisada; mantém orientação | dois quadros reais de idle por vista |
| Caio andar | seis quadros por ciclo; avanço ligado à distância percorrida | revisar todas as transições e vistas espelhadas |
| Caio correr | seis quadros do pacote, fôlego e cadência por deslocamento | revisão visual das vistas geradas |
| Caio empurrar | antecipação → contato → recuperação, 0,65 s | interpolação entre poses e quarto quadro |
| Caio impacto | pose de reação, interrupção e ferimento | segundo quadro e recuo desenhado |
| Caio pegar/curar/cair | poses específicas; cura consome no contato | transições completas, levantar e recuperação |
| Caio sentar/deitar/digitar/alcançar | quatro poses originais na folha caio_home_poses_v1, com âncoras de uso no apartamento | ciclos de entrada/saída quadro a quadro e vistas adicionais; a mudança para a pose ainda é direta |
| Davi | identidade CHR_DAVI, aviso de 0,65 s, contato com alcance e obstáculo, pausa entre ataques | ciclos próprios completos de todos os estados |
| Inês/Orlando/Nestor/Marina/Bia | poses corretas e posições por cena | idle/caminhada e rotinas do primeiro dia |
| Fubá/Breu/Pingo | seis quadros SE, interações opcionais, reação do pássaro | outras direções, repouso e voo verdadeiro |
| Sedã/van/ônibus | estados aberto/fechado, colisão, ônibus em cena curta | entrada/saída, Caio sentado e vistas adicionais |

## Regras do motor

- Fonte 128 × 128; pivô humano (64,120), apresentação 80 × 80. Colisão usa pés, sem incluir o retângulo transparente do PNG.
- `SpriteFacing` é o único dono da adaptação entre direção da tela e arquivos. Caminhada/poses e corrida têm tabelas próprias, pois o erro de rótulo é diferente entre esses lotes. O rótulo NE do lote corresponde visualmente a uma vista lateral; não é usado cegamente como ângulo de câmera.
- Movimento é normalizado. A animação avança por distância efetivamente percorrida; encostar na parede não faz os pés continuarem andando.
- Empurrão só causa efeito no instante de contato, dentro de alcance, na frente de Caio e sem obstáculo no segmento.
- Davi anuncia o ataque; dano depende da distância e linha livre no contato. Seu corpo não pode ser atravessado.
- Cura exige segurança e recurso; não consome ao abrir uma tela e não pode ser iniciada duas vezes ao mesmo tempo.
- Gestos provisórios não são apresentados como Libras validada. Caio continua sem voz.

As poses e os estados implementados não significam que os ciclos finais do catálogo estejam completos.
