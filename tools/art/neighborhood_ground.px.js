// Original SILÊNCIO materials. 2:1 projection, no raised rim or baked shadow.
// Grass grows in short blades; asphalt has aggregate; paving has slab joints.
for (let variant = 0; variant < 4; variant++) {
  sprite(`neighborhood_grass_${variant}`, {w:64,h:32}, c => {
    c.poly([32,0,64,16,32,32,0,16], '#66764d');
    for (let y = 2; y < 31; y += 2) {
      for (let x = 1; x < 63; x++) {
        const hash = (x * 73 + y * 151 + variant * 41) % 101;
        if (Math.abs(x - 32) + Math.abs(y - 16) * 2 > 28 || hash > 16) continue;
        c.line(x,y,x + (hash % 3 - 1),y-1, hash % 2 ? '#7d895b' : '#53643f',1);
      }
    }
  });
  sprite(`neighborhood_concrete_${variant}`, {w:64,h:32}, c => {
    c.poly([32,0,64,16,32,32,0,16], variant % 2 ? '#aaa791' : '#ada994');
    c.line(0,16,32,0,'#969681',1);
    c.line(32,0,63,16,'#bcb6a1',1);
    if (variant === 2) {
      // One faint corner fracture, not a repeated crater.
      c.line(46,8,42,12,'#969681',1);
      c.line(42,12,44,14,'#969681',1);
    }
  });
}
sprite('neighborhood_sidewalk', {w:64,h:32}, c => {
  c.poly([32,0,64,16,32,32,0,16], '#b5ae99');
  c.line(0,16,32,0,'#9a9884',1);
  c.line(32,0,63,16,'#c6bfa9',1);
});
sprite('neighborhood_asphalt', {w:64,h:32}, c => {
  c.poly([32,0,64,16,32,32,0,16], '#626765');
  for (let y=2;y<31;y++) for (let x=1;x<63;x++) {
    if (Math.abs(x-32)+Math.abs(y-16)*2>29) continue;
    const n=(x*37+y*71)%137;
    if(n<5) c.px(x,y,n%2?'#6a6e69':'#5a605d');
  }
});
