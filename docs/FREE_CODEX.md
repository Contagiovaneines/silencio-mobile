# FreeLLMAPI gratuito no Codex

## Uso

1. Mantenha FreeLLMAPI aberto; painel em http://127.0.0.1:31415.
2. Execute `C:/Users/giovane/.codex/ai-tools/Abrir-Codex-FreeLLMAPI-Gratis.cmd`.
3. O atalho abre uma NOVA sessão Codex na pasta SILÊNCIO, com perfil `ia-freellmapi` e modelo `nemotron-3.5-lightning`.

Não exige sua chave OpenRouter, conta Kilo, cartão ou créditos: usa o acesso anônimo do Kilo para `nvidia/nemotron-3.5-lightning:free`. A chave local do FreeLLMAPI é obtida pela API desktop de loopback, passada só no ambiente do processo e restaurada ao encerrar. Não é exibida nem gravada no atalho. Apenas este perfil opcional foi ajustado; o provedor padrão desta conversa não foi alterado.

## Evidência de teste

Codex CLI 0.165.0-alpha.1.2, FreeLLMAPI 0.16.11. Teste real com prompt genérico e sem leitura de arquivos terminou com saída `OK`, evento `turn.completed` e exit code 0. A resposta levou cerca de 70 segundos. Evidência em `qa-freellmapi/kilo-codex.jsonl`.

Um teste de API separado com timeout de 45 segundos não concluiu dentro desse prazo; a solicitação foi cancelada. Isso não equivale a falha de autenticação. Há aviso de metadados ausentes para o modelo no CLI, que utiliza metadados de fallback.

O teste de ferramenta real também PASSOU: o Codex executou `Write-Output QA_TOOL_OK`, recebeu `QA_TOOL_OK`, respondeu com esse valor e encerrou com `turn.completed` e exit code 0. Evidência: `qa-freellmapi/kilo-codex-tools.jsonl`. Isso confirma o ciclo de ferramenta de terminal testado; não é uma validação de todas as ferramentas, imagens ou qualidade de desenvolvimento do jogo. Nenhum código ou asset do jogo foi usado nos testes.

## Limites e dados

O Kilo documenta acesso anônimo apenas para modelos gratuitos, com limite de 200 solicitações/hora por IP e possíveis restrições adicionais. Disponibilidade e latência variam. Não foi configurada conta paga ou fallback com chave pessoal. O catálogo pode exibir outros modelos; listagem não comprova acesso gratuito. Este atalho fixa o modelo testado.

Os endpoints gratuitos NVIDIA são para testes e suas condições dizem para não enviar informações pessoais ou confidenciais; prompts/resultados podem ser registrados para melhoria do serviço. Avalie essas condições antes de usar código privado ou conteúdo inédito do jogo. O teste realizado enviou somente instruções genéricas de QA.

Fontes: https://kilo.ai/docs/gateway/authentication ; https://kilo.ai/docs/gateway/models-and-providers
