"""Install reviewed pxl exports; authoring sources and previews stay outside APK."""
from pathlib import Path
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
manifest_path = ROOT / 'assets/data/phase_assets.json'
manifest = json.loads(manifest_path.read_text(encoding='utf8'))
catalog = {'projection':'2:1 isometric', 'actors':{}, 'building':{}}
actors = ROOT / 'assets/images/actors'
actors.mkdir(exist_ok=True)
for source in sorted((ROOT/'tools/art/out/actors/sprites').glob('actor_*.png')):
    stem=source.stem.removeprefix('actor_')
    state=next(state for state in ['guard_walk','idle','walk','run','attack','guard','hurt'] if stem.endswith('_'+state))
    name=stem[:-(len(state)+1)]
    destination = actors/source.name
    shutil.copy2(source,destination)
    image=Image.open(source)
    catalog['actors'][source.stem]={'path':f'actors/{source.name}', 'cell':[128,144], 'directions':8,
        'frames':image.width//128, 'pivot':[64,119], 'size':list(image.size)}
    if state in ('idle','walk') or name.startswith('caio') or name in ('davi','bruno') and state in ('attack','hurt','guard'):
        manifest[source.stem]=f'actors/{source.name}'
for source in sorted((ROOT/'tools/art/out/building-kit/sprites').glob('kit_*.png')):
    destination=ROOT/'assets/images/pixel_tiles/sprites'/source.name
    shutil.copy2(source,destination)
    image=Image.open(source).convert('RGBA')
    catalog['building'][source.stem]={'path':f'pixel_tiles/sprites/{source.name}', 'size':list(image.size), 'bounds':list(image.getbbox())}
    manifest[source.stem]=f'pixel_tiles/sprites/{source.name}'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(ROOT/'assets/data/asset_pack_v1.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(f"Installed {len(catalog['actors'])} actor sheets and {len(catalog['building'])} architecture sprites.")
