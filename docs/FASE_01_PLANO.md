# Fase 01 — Um Dia Normal

Referência: PDF do projeto, páginas 9–11, 39–45, 102–103 e 112–116. Prioridade do pedido: celular primeiro, Flutter + Flame; revisão atual também deve funcionar no PC. O PDF propõe Godot/PC em algumas páginas; isso não substitui a escolha do usuário.

## Percurso e localização

1. Abertura: laboratório, doze anos antes; cinco momentos, avanço e pular, sem revelar o nome da criança.
2. Apartamento, 07:12: celular/caderno disponíveis, chave e adaptador coletáveis, cama como ponto seguro.
3. Hall: Dona Inês e sacola rasgada; ajuda opcional.
4. Garagem: Fubá e sedã de Orlando. Porta-malas bloqueado até autorização; uma atadura apenas.
5. Mercearia: interior acessível pela porta sul; entrega a Orlando, tomada e notícia. Helena envia mensagens e não ocupa a rua como NPC.
6. Praça: Marina, Bia e Pingo; passagem para o beco e parada. Breu permanece junto à janela do residencial.
7. Beco: Davi em crise. Empurrar cria distância; a alavanca resolve o encontro sem matar. Dar a volta e manter distância também resolve.
8. Ônibus: Nestor oferece trajeto curto opcional. A passagem a pé produz o mesmo evento principal.
9. Primeiro pulso: movimento do mundo interrompido por dois segundos, Caio consciente e pista textual sem depender do som.
10. Mensagem noturna: celular no HUD; volta ao apartamento, cama e salvamento. A fase 02 aparece apenas como gancho, sem conteúdo jogável.

O mapa desenha a posição real dos edifícios, veículos, interações e do jogador. Não teletransporta nem substitui a navegação.

## Seis blocos de produção

| Bloco | Entrega na versão 0.2 | Aceite |
|---|---|---|
| 1. Movimento e colisões | direção visual revisada, orientação ao parar, corrida, colisão nos pés | Não atravessar parede, pessoa ou carro; caminho automático respeita segmentos |
| 2. Mapa e interiores | apartamento, hall/garagem, rua, mercearia, praça/beco, mobiliário e veículos | Percurso conectado; portas legíveis; pontos interativos alcançáveis |
| 3. Roteiro e progressão | coleta, entrega, notícias, crise, pulso, retorno | Sem coletar item duas vezes; não concluir na primeira saída da rua |
| 4. Encontro e animação | antecipação, contato, recuperação, reação, cura e derrota | Dano só depois do aviso e com linha livre; tratar consome no contato |
| 5. Apresentação e áudio | menu, abertura encenada, mapa, retratos, sons sintéticos e opção de silenciar | Texto legível, som opcional, sem voz de Caio, informações também visuais |
| 6. Validação | testes de regras, navegação, UI pequena e conferência web no PC | Registrar o que foi realmente executado; celular fica pendente enquanto indisponível |

## O que ainda exige acabamento artístico

- Cenário: mobília e paredes ainda são geometria desenhada no motor. Refinar detalhes, iluminação, calçadas, vegetação, portas e escala após a prova de percurso.
- Completar oito direções autorais e continuidade de Caio; os nomes de arquivos do pacote não correspondiam sempre à câmera. A adaptação visual usa mapeamento revisado e espelhamento em algumas vistas.
- Davi precisa de ciclos desenhados de caminhada, antecipação, ataque, impacto e recuperação. O protótipo usa a pose correta com encenação/transformação no motor; isso não equivale a esses ciclos prontos.
- NPCs ainda usam poses, não ciclos completos de rotina. Animais têm seis quadros SE e reação simples, não oito vistas nem voo completo.
- Veículos têm estados aberto/fechado e colisão. O ônibus tem transporte roteirizado; não há direção livre nem Caio sentado animado.
- A abertura está encenada com formas e texto. Refinar a arte mantendo a criança sem identificação e sem apresentar a revelação do capítulo 7.
- Os sons são originais de protótipo; substituir sinais sintéticos de animais e efeitos por gravações finais revisadas.
- Testar de novo no celular quando disponível. Não considerar desempenho móvel, bateria ou controles finais aprovados por testes no navegador.

A história completa e os outros capítulos continuam fora deste lote. Primeiro estabilizar e revisar visualmente a fase 01 com o usuário.
