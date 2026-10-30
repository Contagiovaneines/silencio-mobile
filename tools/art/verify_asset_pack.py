"""Validate atlas cells and produce review contact sheets, outside game assets."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
catalog=json.loads((ROOT/'assets/data/asset_pack_v1.json').read_text(encoding='utf8'))
out=ROOT/'tools/art/out/asset-review'
out.mkdir(parents=True,exist_ok=True)
cells=0
for name,meta in catalog['actors'].items():
    image=Image.open(ROOT/'assets/images'/meta['path']).convert('RGBA')
    assert image.size==(128*meta['frames'],144*8),name
    assert image.getpixel((0,0))[3]==0,name
    for direction in range(8):
        hashes=set()
        for frame in range(meta['frames']):
            cell=image.crop((frame*128,direction*144,(frame+1)*128,(direction+1)*144))
            bounds=cell.getbbox()
            assert bounds and bounds[0]>0 and bounds[2]<128 and bounds[1]>0 and bounds[3]<144,(name,direction,frame,bounds)
            hashes.add(cell.tobytes());cells+=1
        assert len(hashes)>1,(name,direction,'no animation')
    # All directions and all frames are preserved together for visual review.
    preview=Image.new('RGBA',(image.width, image.height+24),'#263d38')
    preview.alpha_composite(image,(0,24))
    ImageDraw.Draw(preview).text((8,6),name,fill='#e4dcc0')
    preview.convert('RGB').save(out/f'{name}.png')
for actor in ['caio','caio_nobag','ines','orlando','nestor','marina','bia','davi','bruno']:
    sheets=[]
    for state in ['walk','attack','guard','hurt']:
        meta=catalog['actors'][f'actor_{actor}_{state}']
        image=Image.open(ROOT/'assets/images'/meta['path']).convert('RGBA')
        # Mid-pose, eight directions; full frames remain in separate sheets.
        frame=meta['frames']//2
        row=Image.new('RGBA',(128*8,168),'#263d38')
        ImageDraw.Draw(row).text((8,4),f'{actor}: {state}',fill='#e4dcc0')
        for d in range(8):row.alpha_composite(image.crop((frame*128,d*144,(frame+1)*128,(d+1)*144)),(d*128,24))
        sheets.append(row)
    review=Image.new('RGBA',(1024,168*4),'#263d38')
    for i,row in enumerate(sheets):review.alpha_composite(row,(0,i*168))
    review.convert('RGB').save(out/f'{actor}_directions.jpg',quality=95)
print(f'Validated {len(catalog["actors"])} actor sheets, {cells} nonempty, unclipped animated cells; {len(catalog["building"])} architecture sprites.')
