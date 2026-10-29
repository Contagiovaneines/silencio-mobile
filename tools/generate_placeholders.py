"""Original pixel placeholders for Silêncio; reproducible and replaceable."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'images'
OUT.mkdir(parents=True,exist_ok=True)
PALETTES={
 'caio': {'coat':'#3c535b','light':'#60757b','pants':'#263844','skin':'#c69e7f','hair':'#20292d','bag':'#6a7352'},
 'helena': {'coat':'#874b54','light':'#b27377','pants':'#293c47','skin':'#b78869','hair':'#312927','bag':'#947b55'},
 'neighbor': {'coat':'#8d7956','light':'#b49b70','pants':'#394044','skin':'#c29c84','hair':'#747c77','bag':'#656f5b'},
 'dominated': {'coat':'#4d635e','light':'#73847b','pants':'#3b4749','skin':'#9cae9f','hair':'#303c36','bag':'#535d4c'},
}
for name,p in PALETTES.items():
 sheet=Image.new('RGBA',(128,384))
 for direction in range(8):
  for frame in range(4):
   im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);bob=1 if frame in (1,3) else 0
   back=direction in (0,1,7);side=direction in (2,6);lean=1 if direction in (1,2,3) else -1 if direction in (5,6,7) else 0
   y=bob;step=[0,2,0,-2][frame];outline='#152329'
   d.rectangle((10+lean,30+y,15+lean,42+y+step//2),fill=outline)
   d.rectangle((17+lean,30+y,22+lean,42+y-step//2),fill=outline)
   d.rectangle((11+lean,31+y,14+lean,41+y+step//2),fill=p['pants'])
   d.rectangle((18+lean,31+y,21+lean,41+y-step//2),fill=p['pants'])
   d.rectangle((9+lean,41+y+step//2,15+lean,44+y+step//2),fill='#1a252c')
   d.rectangle((17+lean,41+y-step//2,23+lean,44+y-step//2),fill='#1a252c')
   d.polygon([(10,17+y),(21,17+y),(24,21+y),(23,33+y),(9,33+y),(8,22+y)],fill=outline)
   d.rectangle((10,18+y,21,31+y),fill=p['coat']);d.rectangle((11,19+y,13,29+y),fill=p['light'])
   d.rectangle((6,20+y-step//2,9,32+y-step//2),fill=p['coat']);d.rectangle((22,20+y+step//2,25,32+y+step//2),fill=p['coat'])
   d.rectangle((6,32+y-step//2,9,35+y-step//2),fill=p['skin']);d.rectangle((22,32+y+step//2,25,35+y+step//2),fill=p['skin'])
   d.rectangle((14,14+y,18,19+y),fill=p['skin'])
   d.rectangle((10+lean,5+y,21+lean,15+y),fill=outline);d.rectangle((11+lean,6+y,20+lean,15+y),fill=p['skin'])
   d.rectangle((11+lean,4+y,20+lean,8+y),fill=p['hair']);d.rectangle((10+lean,7+y,12+lean,12+y),fill=p['hair'])
   if back:d.rectangle((11+lean,6+y,20+lean,14+y),fill=p['hair'])
   elif side:d.point((19+lean if lean>=0 else 12+lean,11+y),fill='#17272b')
   else:
    d.point((13+lean,11+y),fill='#17272b');d.point((18+lean,11+y),fill='#17272b');d.line((14+lean,14+y,17+lean,14+y),fill='#996f58')
   if name=='caio':
    if back:d.rectangle((12,20+y,21,30+y),fill=p['bag']);d.line((13,22+y,19,22+y),fill='#929576')
    else:d.line((10,18+y,21,30+y),fill=p['bag'],width=2)
   if name=='helena':
    d.ellipse((8+lean,3+y,21+lean,10+y),fill=p['hair']);d.rectangle((23,24+y,27,31+y),fill=p['bag'])
   if name=='dominated' and not back:d.point((13+lean,11+y),fill='#e3b56e')
   sheet.alpha_composite(im,(frame*32,direction*48))
 sheet.save(OUT/f'{name}_sheet.png')
# Small original prop atlas: crate, medical kit, electric box and television.
atlas=Image.new('RGBA',(256,64));d=ImageDraw.Draw(atlas)
d.polygon([(8,24),(31,13),(54,24),(31,36)],fill='#7b7157');d.polygon([(8,24),(31,36),(31,55),(8,43)],fill='#514c3e');d.polygon([(31,36),(54,24),(54,43),(31,55)],fill='#66604b');d.line((9,34,31,46,53,34),fill='#92836a',width=2)
d.rounded_rectangle((76,26,116,49),4,fill='#d2c9af',outline='#344d50',width=2);d.rectangle((92,29,100,46),fill='#a46e5c');d.rectangle((87,35,105,40),fill='#a46e5c');d.line((88,26,88,21,104,21,104,26),fill='#486466',width=3)
d.rectangle((143,9,177,55),fill='#263c43',outline='#80918b',width=2);d.rectangle((148,15,172,34),fill='#344e50');d.rectangle((152,19,158,22),fill='#d7af68');d.line((151,41,169,41),fill='#a4a183',width=2);d.line((151,46,164,46),fill='#a4a183')
d.rounded_rectangle((199,10,250,48),4,fill='#182d34',outline='#678b8c',width=2);d.rectangle((204,15,240,40),fill='#3a7470');d.line((206,31,214,25,223,34,236,24),fill='#9bc4ad',width=2);d.line((222,49,222,55,207,55,239,55),fill='#354e51',width=3)
atlas.save(OUT/'props.png')
icon=Image.new('RGB',(512,512),'#101f28');d=ImageDraw.Draw(icon)
d.rounded_rectangle((34,34,478,478),110,fill='#193439',outline='#537e75',width=5)
d.rectangle((216,174,296,397),fill='#a5b6a3');d.polygon([(202,182),(256,114),(310,182)],fill='#a5b6a3');d.rectangle((242,227,270,259),fill='#192f35');d.line((160,384,352,384),fill='#5d8981',width=7);d.ellipse((242,92,270,120),fill='#e1ac63')
icon.save(OUT/'silencio_icon.png')
for folder,size in [('mipmap-mdpi',48),('mipmap-hdpi',72),('mipmap-xhdpi',96),('mipmap-xxhdpi',144),('mipmap-xxxhdpi',192)]:
 path=ROOT/'android/app/src/main/res'/folder/'ic_launcher.png';path.parent.mkdir(parents=True,exist_ok=True);icon.resize((size,size),Image.Resampling.LANCZOS).save(path)
for name,size in [('Icon-192.png',192),('Icon-512.png',512),('Icon-maskable-192.png',192),('Icon-maskable-512.png',512)]:icon.resize((size,size),Image.Resampling.LANCZOS).save(ROOT/'web/icons'/name)
icon.resize((32,32),Image.Resampling.LANCZOS).save(ROOT/'web/favicon.png')
(OUT/'manifest.json').write_text(json.dumps({'original':True,'generator':'tools/generate_placeholders.py','cell_width':32,'cell_height':48,'columns':4,'rows':8,'directions':['N','NE','E','SE','S','SW','W','NW'],'anchor':'bottom-center','frames':'0 idle; 0,1,2,3 walking loop; placeholders only','replaceable':True},indent=2),encoding='utf-8')
print('Created four 8-direction character sheets, props and application icons.')
