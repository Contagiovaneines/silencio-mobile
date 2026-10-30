// Original SILENCIO equipment. Body animation and possession stay separate.
// Grip is at (16,50) on the 64px world sprite, pointing toward upper right.
const models={
  crowbar(c){c.line(16,50,42,20,'#263e42',7);c.line(16,49,42,19,'#a5b3aa',3);c.line(42,19,47,15,'#a5b3aa',5);c.line(47,15,53,18,'#a5b3aa',5);c.line(53,18,49,23,'#697d79',4);},
  wrench(c){c.line(16,50,40,22,'#304c4d',10);c.line(16,48,40,20,'#9eada0',6);c.poly([32,20,36,12,43,9,39,17,44,23,52,20,49,28,41,31],'#c4c9af');c.ellipse(17,48,3,3,'#3e5b55');},
  pistol(c){c.poly([13,42,22,30,34,35,25,52,18,54],'#354a46');c.poly([17,29,39,10,54,22,32,41],'#263e40');c.line(23,29,40,15,'#7b8e89',5);c.line(39,14,51,23,'#9ba69a',3);c.line(26,40,34,34,'#a48c63',2);},
  rifle(c){c.poly([5,53,16,39,26,45,15,59],'#67513a');c.line(18,44,43,19,'#273e40',10);c.line(28,34,37,39,'#273e40',7);c.line(41,22,58,5,'#82938b',4);c.line(18,41,38,21,'#9ba69b',3);c.line(28,27,33,22,'#334b47',5);},
  baton(c){c.line(16,50,46,15,'#1c3031',9);c.line(17,48,45,16,'#5b706b',3);c.line(24,39,35,43,'#2c4542',5);for(let i=0;i<4;i++)c.line(14+i*2,46-i*2,20+i*2,51-i*2,'#8e9881',1);},
  stick(c){c.line(16,50,43,18,'#4e3527',10);c.line(17,48,44,17,'#b08a58',5);c.line(20,42,38,21,'#d0aa70',2);c.line(24,31,31,33,'#6d4d31',2);c.line(38,21,46,17,'#d0aa70',2);},
  pipe(c){c.line(16,50,43,19,'#314b4f',9);c.line(17,48,44,18,'#9caea5',4);c.line(44,18,50,22,'#839a92',7);c.line(49,22,54,16,'#839a92',7);c.ellipse(54,16,4,3,'#2a4143');c.line(23,40,29,35,'#665846',4);},
  mallet(c){c.line(16,50,38,26,'#5b422c',7);c.line(17,48,38,25,'#c2a06b',3);c.poly([27,12,36,5,58,24,49,33],'#253b39');c.poly([29,12,36,8,54,24,49,28],'#61796d');c.line(32,13,49,27,'#95a08b',2);},
};
for(const [name,draw]of Object.entries(models)){
  sprite(`gear_${name}`,{w:64,h:64},draw);
  sprite(`icon_${name}`,{w:64,h:64},c=>{c.ellipse(32,54,22,4,'#152b2850');draw(c);});
}
sheet('weapon_catalog',Object.keys(models).map(n=>'gear_'+n),{cols:4,pad:10});
