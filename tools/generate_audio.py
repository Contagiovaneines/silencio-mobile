import wave,struct,math,random
from pathlib import Path
r=Path('assets/audio');r.mkdir(exist_ok=True);rate=22050;random.seed(712)
def save(name,seconds,fn):
 with wave.open(str(r/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(b''.join(struct.pack('<h',int(max(-.95,min(.95,fn(i/rate)))*32767)) for i in range(int(rate*seconds))))
save('rain',8,lambda t:random.uniform(-.3,.3)*(.75+.15*math.sin(2*math.pi*t/8)))
for name,freq,secs in [('phone',690,.4),('pickup',940,.25),('heal',420,.65),('alert',140,.5),('bird',1900,.4),('dog',180,.28),('cat',560,.45),('engine',70,1.5)]:
 save(name,secs,lambda t,f=freq,d=secs: .22*math.sin(2*math.pi*(f*t+12*t*t))*math.sin(math.pi*t/d)**2)
for name,secs,amp in [('step',.13,.32),('hit',.22,.5),('push',.32,.35),('door',.7,.4)]:
 save(name,secs,lambda t,d=secs,a=amp:random.uniform(-a,a)*math.exp(-t*12)*(1 if name!='door' else .8))
save('pulse',2,lambda t:.3*math.sin(2*math.pi*(82*t-12*t*t))*math.sin(math.pi*t/2)**2)
Path('docs/AUDIO.md').write_text('''# Áudio original de protótipo

Arquivos WAV mono 22.050 Hz sintetizados localmente por `tools/generate_audio.py`: chuva, passos, interface, empurrão, impacto, cura, portão, motor e sinais estilizados dos animais. Não há voz de Caio. Os sons de animais são substitutos sintéticos curtos, não gravações realistas. Todos têm equivalente visual. Volume moderado, opção de silenciar persistente e pausa ao sair do aplicativo. Substituir por foley e ambientes finais após revisão de direção sonora.
''',encoding='utf8')
