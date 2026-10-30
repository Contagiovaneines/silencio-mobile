"""Install reviewed original gear and record production coverage honestly."""
from pathlib import Path
import json,shutil

ROOT=Path(__file__).resolve().parents[2]
target=ROOT/'assets/images/equipment';target.mkdir(exist_ok=True)
manifest_path=ROOT/'assets/data/phase_assets.json'
manifest=json.loads(manifest_path.read_text(encoding='utf8'))
for image in (ROOT/'tools/art/out/weapons/sprites').glob('*.png'):
    shutil.copy2(image,target/image.name)
    manifest[image.stem]=f'equipment/{image.name}'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
weapons=[
 ('CROWBAR','crowbar','Pé de cabra',3,['caio']),
 ('WRENCH','wrench','Chave de oficina',3,['helena']),
 ('PISTOL','pistol','Pistola',8,['vale']),
 ('RIFLE','rifle','Fuzil',4,['reis','celia']),
 ('BATON','baton','Bastão militar',4,['reis','celia']),
 ('STICK','stick','Bastão de madeira',1,['davi']),
 ('PIPE','pipe','Cano metálico',2,['bruno']),
 ('MALLET','mallet','Malho de borracha',5,['vera']),
]
catalog={'source':{'pdf':'SILENCIO_Historia_Completa_Fases_e_Dialogos.pdf','pages':116,'weapons_page':94},'weapons':{},'characters':{},'legacy_player_weapon':{'path':'item_weapon.png','note':'Arma improvisada já existente. Preservada para não apagar item ou mecânica dos saves. Não concede as armas do catálogo.'}}
for ident,name,label,chapter,owners in weapons:
    catalog['weapons']['WPN_'+ident]={'name':label,'world':f'equipment/gear_{name}.png','icon':f'equipment/icon_{name}.png','grip':[16,50],'size':[64,64],'first_chapter':chapter,'owners':owners,'art_exported':True,'runtime_held':name=='pipe','future_character_animations_complete':False}
gear={
 'caio':['celular','mochila','crowbar'], 'helena':['wrench','câmera','bolsa de câmera'],
 'lia':['bolsa médica'], 'samuel':['prancheta','sensor'], 'vale':['pistol','rádio'],
 'reis':['rifle','baton','rádio'], 'ines':['sacola','chave de serviço'], 'orlando':['bandeja'],
 'davi':['stick'], 'marina':['guarda-chuva'], 'bia':['brinquedo'], 'nestor':['chaves'],
 'teresa':['copo'], 'mauro':['faixa','foto'], 'clara':[], 'rosa':['rádio','água'],
 'joel':['documento'], 'amin':['sensor passivo'], 'arthur':['prancheta'], 'beatriz':['eletrodo'],
 'elisa':['desenho'], 'tadeu':['chaves'], 'bruno':['pipe'], 'vera':['mallet'],
 'celia':['rifle','baton'], 'hugo':['órtese'], 'ivo':['arnês'],
}
runtime={'caio','ines','orlando','davi','marina','bia','nestor','bruno'}
for name,items in gear.items():
    prefix='BOSS_' if name=='ivo' else 'ENM_' if name in {'bruno','vera','celia','hugo'} else 'CHR_'
    catalog['characters'][prefix+name.upper()]={'runtime_id':name,'allowed_equipment':items,'body_cycles_integrated':name in runtime,'all_equipment_variants_complete':False,'combatant':name in {'caio','helena','vale','reis','davi','bruno','vera','celia','hugo','ivo'}}
catalog['coverage']={'caio_backpack_variants':['equipped','removed'],'caio_held_states':['idle','walk','run','attack','guard','hurt'],'free_jump':False,'contextual_vault':False,'public_screen':True,'all_future_cast_complete':False}
(ROOT/'assets/data/equipment_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(f'Installed 16 gear/icon exports; catalog covers 8 weapon models and {len(gear)} distinct identities. Future animations explicitly incomplete.')
