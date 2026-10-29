"""Export existing original references and prompts. Does not change the game."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'prompt'
STYLE = '''SILÊNCIO: jogo mobile em paisagem, cenário isométrico 2.5D com textura pintada e acabamento pixelizado discreto. Brasil contemporâneo, Santa Aurora. Exteriores azul-petróleo/cinza dessaturados, madeira e luz âmbar nos interiores. Preserve perspectiva, proporções e identidade das referências; não transformar em anime de luta, live-action ou 3D brilhante. Caio tem cabelo preto curto e bagunçado, jaqueta escura, mochila e aparência do retrato fornecido. Caio não fala nem narra. Não inventar diálogos, roupas, poderes, monstros, ferimentos ou acontecimentos. Sem HUD, palavras, legendas, marcas ou logotipos gerados; textos serão aplicados no jogo. Sem flashes repetidos, câmera trêmula, morphing, objetos duplicados ou mudança da planta. As capturas do beta contêm HUD: usar somente cenário e composição como referência, excluir toda a interface do resultado. Nunca gerar vídeo dentro de uma folha de sprites ou colagem.'''

SCENES = [
    ('01_abertura', 8, 'silencio_f01_abertura_v01.mp4',
     'Antes da abertura atual; pular leva ao apartamento 203, 07:12, sem marcar objetivos.',
     '''Plano de estabelecimento da cidade numa manhã chuvosa comum. 0–2s: rua e poças, janelas quentes do prédio. 2–6s: deslocamento de câmera muito lento em direção ao prédio; chuva suave e cotidiano discreto, sem revelar ameaça. 6–8s: estabilizar o enquadramento numa janela do segundo andar, mantendo geometria consistente. Não atravessar a parede nem mostrar Caio teleportando. A continuação será um corte feito pelo motor para o apartamento. A imagem conceito da cidade é direção artística, não planta final nem lugar novo canônico.''',
     ['prompt/referencias/santa_aurora_conceito_v01.png', 'docs/screenshots/ap203-final.png', 'assets/images/portrait_caio.png', 'assets/images/apartment_furniture_v1.png', 'assets/audio/rain.wav']),
    ('02_primeiro_pulso', 6, 'silencio_f01_pulso_v01.mp4',
     'No evento _pulse já existente, depois de canLeave; conclusão ou pular usa a mesma rotina do beta, uma única vez.',
     '''Cena na rua junto à parada, fim de tarde; não definir modelo de torre nem nova ameaça. 0–1.5s: pedestres distantes continuam seu movimento cotidiano; Caio está consciente. 1.5–2.5s: o ambiente perde gradualmente saturação e o movimento das pessoas cessa, sem explosão e sem estroboscópio. 2.5–4.5s: pessoas imóveis; somente Caio muda discretamente a postura e olha em volta. 4.5–6s: sustentar a inquietação, sem explicar a causa. Usar o sprite de Caio para identidade; não torná-lo super-herói. Não mostrar ônibus transportando Caio: chegar a pé ou de ônibus são opções válidas. Evitar multidão detalhada sem referências. O som grave será aplicado separadamente pelo motor; entregar imagem sem trilha/voz.''',
     ['prompt/referencias/santa_aurora_conceito_v01.png', 'docs/screenshots/ap203-terreo.png', 'assets/images/portrait_caio.png', 'assets/images/pose_SE_idle.png', 'assets/audio/pulse.wav']),
    ('03_mensagem_helena', 4, 'silencio_f01_mensagem_v01.mp4',
     'Opcional, depois do pulso, ao abrir o celular. Nunca substituir a leitura interativa nem avançar night sozinho.',
     '''Plano curto isométrico do celular segurado por Caio ou sobre superfície neutra. 0–1s: celular apagado. 1–2s: vibração pequena e luz suave da tela. 2–4s: enquadramento estável, tela vazia de texto, deixando área limpa para a interface do jogo. Não mostrar Helena fisicamente, chamada de vídeo, avatar animado ou revelação da localização dela. Não fazer Caio falar. A mensagem real e suas respostas continuarão no sistema de diálogo acessível do motor. Tela sem números, nomes e letras geradas.''',
     ['assets/images/item_phone.png', 'assets/images/portrait_caio.png', 'assets/images/portrait_helena.png', 'assets/audio/phone.wav']),
    ('04_retorno_e_cama', 6, 'silencio_f01_retorno_v01.mp4',
     'Somente ao usar a cama após canLeave + pulse + night. Não acionar ao salvar cedo; nenhuma prévia do capítulo 2.',
     '''Interior do apartamento 203 ao fim do dia, mesma cama, janela, madeira e disposição da referência. 0–2s: Caio já está junto à cama; ele senta com movimento contido. 2–4.5s: deita com anatomia e escala consistentes, mochila fora do colchão, sem se fundir ao móvel. 4.5–6s: câmera fixa e luz quente mais baixa; quadro final calmo. Não acrescentar sonho, ataque, torre acesa ou despertar às duas. A conclusão e o texto sobre o próximo capítulo serão mostrados pelo motor. Se o gerador não preservar a anatomia, usar apenas plano do quarto e realizar o deitar por sprites no jogo; não aprovar deformações.''',
     ['docs/screenshots/ap203-final.png', 'assets/images/portrait_caio.png', 'assets/images/pose_SE_idle.png', 'assets/images/apartment_furniture_v1.png', 'assets/audio/rain.wav']),
]

ANIMATIONS = [
    ('01_deitar', 'Cama', 'aproximar parado; sentar na borda; inclinar; deitar; repouso; levantar em ordem inversa. Manter roupa e cama da referência. Separar corpo do personagem e camadas do móvel para oclusão. Não animar a cama deslizando.'),
    ('02_cadeira', 'Cadeira da escrivaninha', 'parado; flexionar joelhos; abaixar quadril; sentado; digitar sutilmente; levantar. Mãos e pés consistentes, sem atravessar mesa. Entregar pose sentada sem movimento para loop opcional.'),
    ('03_sofa', 'Sofá verde', 'parado; flexionar; sentar; repousar sentado; inclinar para frente; levantar. Preservar escala e encosto do sofá. Sem trocar a roupa ou deformar almofadas.'),
    ('04_armario', 'Armário de madeira', 'armário fechado; portas abrindo em dobradiças; aberto; fechar em ordem inversa. Móvel isolado sem personagem e com a mesma projeção da folha de móveis. Em série separada Caio faz alcance com mão; não adicionar item fictício na mão.'),
    ('05_notebook', 'Notebook da escrivaninha', 'notebook fechado; tampa em meia abertura; tampa aberta; tela com brilho neutro; fechar. Objeto isolado sem texto. Em série separada Caio sentado digita com movimento pequeno. Não inventar aplicações, login ou conteúdo da história.'),
]

def main():
    records = []
    for scene_id, duration, filename, trigger, action, sources in SCENES:
        directory = PACK / 'video' / scene_id
        (directory / 'assets').mkdir(parents=True, exist_ok=True)
        (directory / 'saida').mkdir(exist_ok=True)
        assets = []
        for source in sources:
            original = ROOT / source
            if not original.is_file():
                raise FileNotFoundError(original)
            destination = directory / 'assets' / original.name
            shutil.copy2(original, destination)
            assets.append({'file': 'assets/' + original.name, 'source': source,
                           'sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
                           'role': 'existing_game_reference_not_generated_video'})
        (directory / 'PROMPT.md').write_text(
            f'# {scene_id}\n\n## Referências\n\nAnexar os arquivos de assets como referências, não como quadros de colagem. Retratos fixam identidade; sprites fixam roupa e proporção; captura fixa cenário; WAV é guia para pós-produção, não trilha obrigatória.\n\n## Prompt pronto\n\n{STYLE}\n\n{action}\n\nVídeo único de {duration} segundos, horizontal 16:9, alvo 1920×1080, 24 fps, sem áudio embutido. Movimento discreto, câmera isométrica coerente. Guardar primeiro e último quadro para conferir continuidade.\n\n## Entrega\n\nSalvar `saida/{filename}`. MP4 H.264, yuv420p, SDR. Se o serviço exportar outra resolução, manter 16:9 e informar; não esticar a imagem. A taxa e compressão final serão ajustadas na integração. Versões novas usam v02, v03, sem sobrescrever a aprovada.\n\n## Integração futura\n\n{trigger}\n\nO vídeo é opcional. O beta continua com sua apresentação atual. Material ainda não produzido; esta pasta não contém MP4 fictício.\n', encoding='utf-8')
        (directory / 'saida' / 'COLOQUE_O_VIDEO_AQUI.md').write_text(
            f'Entregar aqui `{filename}`. Nenhum vídeo gerado ainda. Não renomear uma imagem como MP4.\n', encoding='utf-8')
        (directory / 'ASSETS.json').write_text(json.dumps(assets, ensure_ascii=False, indent=2), encoding='utf-8')
        records.append({'id': scene_id, 'duration_seconds': duration, 'status': 'awaiting_user_video',
                        'output': f'{scene_id}/saida/{filename}', 'trigger': trigger, 'required_for_beta': False})
    (PACK / 'video' / 'manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
    for action_id, subject, action in ANIMATIONS:
        directory = PACK / 'animacao' / action_id
        (directory / 'assets').mkdir(parents=True, exist_ok=True)
        (directory / 'saida').mkdir(exist_ok=True)
        references = []
        for source in ['assets/images/portrait_caio.png', 'assets/images/pose_SE_idle.png',
                       'assets/images/apartment_furniture_v1.png', 'docs/screenshots/ap203-final.png']:
            destination = directory / 'assets' / Path(source).name
            shutil.copy2(ROOT / source, destination)
            references.append({'file': 'assets/' + destination.name, 'source': source,
                               'sha256': hashlib.sha256(destination.read_bytes()).hexdigest()})
        (directory / 'ASSETS.json').write_text(json.dumps(references, ensure_ascii=False, indent=2), encoding='utf-8')
        (directory / 'PROMPT.md').write_text(
            f'# {subject} — sprites para interação\n\nEstes quadros ainda serão produzidos. Não são vídeo de cutscene; o motor controla entrada, repouso e saída.\n\n## Prompt\n\n{STYLE}\n\nCriar sprites de {subject}, mantendo exatamente a identidade e o tamanho aparente das referências. A captura fixa contexto e a folha de móveis fixa material/forma; não exportar seu fundo nem HUD. Sequência: {action}\n\nProduzir primeiro uma direção compatível com o objeto no cenário, SE, para validar encaixe. Exportar cada estado em PNG RGBA com fundo realmente transparente, contorno limpo sem halo, câmera e escala constantes, sem chão pintado ou sombra de fundo. Não entregar colagem com títulos nem perspectiva variando por quadro. Depois da primeira direção aprovada, produzir as direções necessárias para cada âncora do cenário; não espelhar texto, mochila ou assimetrias. Para transições suaves usar 6 quadros de entrada e 6 de saída, com um quadro de repouso; a duração será controlada pelo motor. Não usar interpolação que deforme mãos.\n\n## Entrega\n\nGuardar os PNG em saida, nomeando por exemplo `{action_id}_SE_enter_00.png` a `_05.png`, `{action_id}_SE_idle_00.png`, `{action_id}_SE_exit_00.png` a `_05.png`. Para objeto separado usar prefixo object; para corpo usar caio. Não colar corpo no móvel. Manter canvas constante e registrar em JSON o tamanho, direção, ordem e ponto de apoio em pixels. A escala final e a âncora de assento/cama precisam ser medidas na integração; não presumir que o pé continua sendo a âncora da pose deitada. Referência de pé: pose_SE_idle.png.\n\nNão substituir as imagens de assets. Rig/sprites ainda precisam de revisão de alinhamento e colisão no jogo.\n', encoding='utf-8')
    print(f'Prepared {len(records)} scene packs in {PACK}')

if __name__ == '__main__':
    main()
