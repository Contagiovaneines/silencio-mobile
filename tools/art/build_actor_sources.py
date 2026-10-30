"""Serialize original project skins into editable pxl source, not runtime code.

Cropping and nearest-neighbor normalization prepare generated supplemental views.
Pose construction happens in actor_cycles.px.js through the project-local pxl DSL.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools/art/source/npc_views'
NAMES = ['ines', 'orlando', 'nestor', 'marina', 'bia', 'davi']
MAP = [('NE',False),('SW',True),('S',False),('SW',False),('W',False),('NW',True),('N',False),('NW',False)]
# Backpack run inputs do not keep the same facing across all six source poses.
# Normalize once per pose, in runtime row order E, SE, S, SW, W, NW, N, NE.
# W/f5 faces right (W/f0-f4 face left); SE/f3-f5 and NW/f4-f5
# also change side. NE/f5 already faces right and needs no extra mirror.
RUN_MAP = [
    ('W',  (True,  True,  True,  True,  True,  False)),
    ('SE', (True,  True,  True,  False, False, False)),
    ('S',  (False, False, False, False, False, False)),
    ('SE', (False, False, False, True,  True,  True)),
    ('W',  (False, False, False, False, False, True)),
    ('NW', (False, False, False, False, True,  True)),
    ('N',  (False, False, False, False, False, False)),
    ('NE', (False, False, False, False, False, False)),
]


def normalize(image, height):
    image = image.convert('RGBA')
    bounds = image.getchannel('A').point(lambda a: 255 if a > 96 else 0).getbbox()
    image = image.crop(bounds)
    image = image.resize((round(image.width * height / image.height), height), Image.Resampling.NEAREST)
    result = Image.new('RGBA', (128,128))
    result.paste(image, (64-image.width//2,120-height))
    return result


def nobag_locomotion_cells(sheet, state, target_height=97):
    """Return Caio's authored 8x6 locomotion cells at one body scale.

    Normalize each frame directly to the shared target. Scaling each frame by
    its own source height first compounds pose-height differences and makes
    Caio visibly change size between gait frames.
    """
    if state not in ('walk', 'run'):
        raise ValueError(f'unsupported locomotion state: {state}')
    sheet = sheet.convert('RGBA')
    cells = [
        [
            sheet.crop((round(frame*sheet.width/6), round(direction*sheet.height/8),
                        round((frame+1)*sheet.width/6), round((direction+1)*sheet.height/8)))
            for frame in range(6)
        ]
        for direction in range(8)
    ]
    for direction, row in enumerate(cells):
        for frame, image in enumerate(row):
            skin = normalize(image, target_height)
            if state == 'run' and frame == 5 and direction in (0, 4):
                skin = skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            cells[direction][frame] = skin
    return cells


def runs(image):
    image = image.convert('RGBA')
    result = []
    for y in range(128):
        x = 0
        while x < 128:
            color = image.getpixel((x,y))
            if color[3] < 96:
                x += 1
                continue
            # A restrained 5-bit palette preserves identity and compresses spans.
            color = tuple((v//8)*8 for v in color[:3])
            end = x+1
            while end < 128:
                other = image.getpixel((end,y))
                if other[3] < 96 or tuple((v//8)*8 for v in other[:3]) != color: break
                end += 1
            result.append([x,y,end-x,'#'+''.join(f'{v:02x}' for v in color)])
            x = end
    return result


def main():
    data = {}
    actions = {}
    npc_actions = {}
    modular_actions = {}
    modular_locomotion = {}
    for name in NAMES:
        front = Image.open(ROOT / f'assets/images/phase_{name}.png').convert('RGBA')
        h = front.getbbox()[3]-front.getbbox()[1]
        left = normalize(Image.open(SOURCE / f'{name}_back_left.png'),h)
        right = normalize(Image.open(SOURCE / f'{name}_back_right.png'),h)
        directions = []
        for d in range(8):
            skin = left if d in (5,6) else right if d == 7 else front
            if d in (0,1): skin = skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            directions.append(runs(skin))
        data[name] = directions
    directions = []
    for name,mirror in MAP:
        skin = Image.open(ROOT / f'assets/images/pose_{name}_idle.png')
        if mirror: skin = skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        directions.append(runs(skin))
    data['caio'] = directions
    davi_files=list(SOURCE.glob('davi_action_*.png'))
    if davi_files:
        def bounds_height(p):
            im=Image.open(p).convert('RGBA'); b=im.getchannel('A').point(lambda a:255 if a>96 else 0).getbbox(); return b[3]-b[1]
        common=max(bounds_height(p) for p in davi_files)
        base=Image.open(ROOT/'assets/images/phase_davi.png').getbbox(); height=base[3]-base[1]
        for state in ['attack','hurt','guard']:
            npc_actions[state]=[]
            for d in range(8):
                views=[]
                for f in range(3):
                    p=SOURCE/f'davi_action_{state}_{f}.png'
                    skin=normalize(Image.open(p),round(height*bounds_height(p)/common))
                    if d in (3,4):skin=skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                    views.append(runs(skin))
                npc_actions[state].append(views)
        rear_source=SOURCE/'davi_rear_attack_source.png'
        if rear_source.exists():
            sheet=Image.open(rear_source).convert('RGBA')
            cells=[[sheet.crop((round(col*sheet.width/3),round(row*sheet.height/3),round((col+1)*sheet.width/3),round((row+1)*sheet.height/3))) for col in range(3)] for row in range(3)]
            def body_height(im):
                b=im.getchannel('A').point(lambda a:255 if a>96 else 0).getbbox()
                return b[3]-b[1]
            common_rear=max(body_height(im) for row in cells for im in row)
            for row in range(3):
                views=[runs(normalize(im,round(height*body_height(im)/common_rear))) for im in cells[row]]
                npc_actions['attack'][5+row]=views
                npc_actions['guard'][5+row]=[views[0]]
    locomotion = {}
    walk_map = [(direction, (mirror,) * 6) for direction, mirror in MAP]
    for state, mapping in [('walk',walk_map),('run',RUN_MAP)]:
        locomotion[state] = []
        for d,(direction, mirrors) in enumerate(mapping):
            views = []
            for f in range(6):
                filename = f'user_caio_{direction}_{f}.png' if state=='walk' else f'run_{direction}_{f}.png'
                skin = Image.open(ROOT / 'assets/images' / filename)
                if mirrors[f]: skin = skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                views.append(runs(skin))
            locomotion[state].append(views)
    for state, poses in {'attack':['push_anticipation','push_contact','push_recover'], 'guard':['push_contact'], 'hurt':['hurt']}.items():
        actions[state] = []
        for direction, mirror in MAP:
            views = []
            for pose in poses:
                skin = Image.open(ROOT / f'assets/images/pose_{direction}_{pose}.png')
                if mirror: skin = skin.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                views.append(runs(skin))
            actions[state].append(views)
    for name,height in [('caio_nobag',97),('bruno',102)]:
        sheet=Image.open(ROOT/f'tools/art/source/equipment_variants/{name}_templates.png').convert('RGBA')
        rows=[0,281,539,771,sheet.height] if name=='bruno' else [round(i*sheet.height/4) for i in range(5)]
        cells=[[sheet.crop((round(col*sheet.width/4),rows[row],round((col+1)*sheet.width/4),rows[row+1])) for col in range(4)] for row in range(4)]
        def body_height(im):
            b=im.getchannel('A').point(lambda a:255 if a>96 else 0).getbbox()
            return b[3]-b[1]
        common=max(body_height(im) for row in cells[:2] for im in row)
        def skin(row,col,mirror=False):
            im=cells[row][col]
            im=normalize(im,round(height*body_height(im)/common))
            if mirror:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            return runs(im)
        mapping=[(0,3,False),(1,0,False),(1,1,False),(1,2,False),(1,3,False),(0,0,True),(0,1,False),(0,2,False)]
        data[name]=[skin(*view) for view in mapping]
        modular_actions[name]={state:[] for state in ['attack','guard','hurt']}
        for d in range(8):
            row=3 if d>=5 else 2
            mirror=d in (3,4,5)
            modular_actions[name]['attack'].append([skin(row,f,mirror) for f in range(3)])
            modular_actions[name]['guard'].append([skin(row,0,mirror)])
            modular_actions[name]['hurt'].append([skin(row,3,mirror)])
    modular_locomotion['caio_nobag']={}
    for state in ['walk','run']:
        sheet=Image.open(ROOT/f'tools/art/source/equipment_variants/caio_nobag_{state}_frames.png').convert('RGBA')
        cells=nobag_locomotion_cells(sheet,state)
        modular_locomotion['caio_nobag'][state]=[[runs(im) for im in row] for row in cells]
    output = ROOT / 'tools/art/actor_skins.px.js'
    output.write_text('// Original SILÊNCIO skins serialized as editable pixel spans.\nconst actorSkins = '+json.dumps(data,separators=(',',':'))+';\nconst caioActionSkins = '+json.dumps(actions,separators=(',',':'))+';\nconst caioLocomotionSkins = '+json.dumps(locomotion,separators=(',',':'))+';\nconst daviActionSkins = '+json.dumps(npc_actions,separators=(',',':'))+';\n',encoding='utf8')
    with output.open('a',encoding='utf8') as stream:
        stream.write('const modularActionSkins = '+json.dumps(modular_actions,separators=(',',':'))+';\n')
        stream.write('const modularLocomotionSkins = '+json.dumps(modular_locomotion,separators=(',',':'))+';\n')
    print(f'{output.name}: {output.stat().st_size} bytes; eight identities plus Caio without backpack, eight direction slots.')


if __name__ == '__main__': main()
