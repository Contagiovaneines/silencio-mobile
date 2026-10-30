// SILÊNCIO original modular 2:1 architecture. Pixel sources, no PZ resources.
const C={ink:'#283b3c', plaster:'#aaa992',light:'#cec7ad',shade:'#858e7d',trim:'#d7ceb2',wood:'#806346',woodLight:'#ae8b61',glass:'#567a7b',metal:'#788e8a'};
function panel(c,a,b,h,color) { c.poly([a[0],a[1],b[0],b[1],b[0],b[1]-h,a[0],a[1]-h],color); }
function wall(c,kind){
  panel(c,[8,72],[72,104],64,kind==='exterior'? '#87947e':C.plaster);
  panel(c,[72,104],[77,101],64,C.shade);
  c.poly([8,8,13,5,77,37,72,40],C.trim);
  c.line(8,68,72,100,'#6c6f5b',4);
  c.line(8,66,72,98,C.light,1);
  for(let y=18;y<64;y+=12) c.line(8,y,72,y+32,kind==='exterior'?'#7d8975':'#a1a18b',1);
  if(kind==='brick') for(let row=0;row<7;row++){
    const y=12+row*8;c.line(8,y,72,y+32,'#919581',1);
    for(let x=8+(row%2)*8;x<72;x+=16){const yy=y+(x-8)/2;c.line(x,yy,x,yy+7,'#919581',1);}
  }
  if(kind==='wallpaper') for(let x=12;x<72;x+=8)c.line(x,12+(x-8)/2,x,67+(x-8)/2,'#989b81',1);
}
for(const kind of ['plaster','brick','wallpaper','exterior']){
  sprite(`kit_wall_${kind}_east`,{w:80,h:112},c=>wall(c,kind));
  sprite(`kit_wall_${kind}_west`,{base:`kit_wall_${kind}_east`,flip:'x'});
}
for(const state of ['closed','open','broken']){
  sprite(`kit_window_${state}_east`,{w:64,h:80},c=>{
    panel(c,[8,48],[56,72],42,C.trim);
    panel(c,[12,46],[52,66],34,C.ink);
    if(state==='closed'){
      panel(c,[14,44],[50,62],30,C.glass);
      c.line(31,25,31,53,C.trim,2);c.line(14,30,50,48,C.trim,2);
      c.line(17,24,27,29,'#99c5d0',3);c.line(35,45,46,51,'#88a89c',1);
      c.line(22,20,28,23,'#99c5d0',3);
    }else if(state==='open'){
      c.poly([11,13,28,11,28,48,11,47],C.trim);c.poly([14,16,25,15,25,45,14,43],C.glass);
    }else{
      c.poly([14,14,24,19,20,29,14,25],C.glass);c.poly([40,30,50,32,50,61,44,54,47,43],C.glass);
    }
    c.poly([6,48,56,73,60,70,10,45],C.light);c.line(8,49,56,73,'#727865',2);
  });
  sprite(`kit_window_${state}_west`,{base:`kit_window_${state}_east`,flip:'x'});
}
for(const state of ['closed','open','frame']){
  sprite(`kit_door_${state}`,{w:80,h:112},c=>{
    c.line(10,74,10,10,C.trim,5);c.line(65,102,65,38,C.trim,5);c.line(10,10,65,38,C.trim,5);
    panel(c,[13,73],[62,98],59,C.ink);
    if(state==='closed'){
      panel(c,[14,72],[61,96],56,C.wood);
      for(let x=20;x<60;x+=9)c.line(x,18+(x-14)/2,x,68+(x-14)/2,C.woodLight,1);
      c.ellipse(53,67,2,2,'#d2b16d');
    }else if(state==='open'){
      panel(c,[10,74],[37,68],60,C.wood);c.line(36,10,36,65,C.woodLight,2);c.ellipse(31,42,2,2,'#d2b16d');
    }
    c.line(9,76,65,104,'#b3a88a',3);
  });
}
function box(c,x,y,w,d,h,top,front,side){
  const a=[x,y],b=[x+w,y+w/2],z=[x+w-d,y+w/2+d/2],e=[x-d,y+d/2];
  panel(c,e,z,h,front);panel(c,b,z,h,side);
  c.poly([a[0],a[1]-h,b[0],b[1]-h,z[0],z[1]-h,e[0],e[1]-h],top);
}
sprite('kit_fridge',{w:96,h:128},c=>{
  box(c,43,74,31,29,65,'#c8d0bf','#a4b7ab','#819d96');
  c.line(16,42,46,57,'#748e85',2);c.line(16,58,46,73,'#d8ddc9',1);
  c.line(39,42,39,51,C.ink,2);c.line(39,60,39,77,C.ink,2);
  for(let y=80;y<88;y+=3)c.line(18,y,37,y+9,'#718980',1);
});
sprite('kit_bench',{w:128,h:96},c=>{
  for(const x of [29,85]) { c.line(x,49,x,77,'#404e48',5); c.line(x-13,55,x-13,83,'#303f3d',4); }
  box(c,29,60,66,23,10,'#a68c65','#7f6b4f','#665c48');
  for(let n=0;n<3;n++)c.line(9+n*7,52-n*3,75+n*7,85-n*3,'#554c3e',1);
  box(c,33,36,66,5,20,'#b19b74','#857456','#685d49');
});
sprite('kit_shop_shelf',{w:128,h:144},c=>{
  box(c,35,88,70,27,70,'#a79269','#88744f','#675c44');
  for(let level=0;level<3;level++){
    const y=31+level*21;panel(c,[13,y+8],[79,y+41],15,'#4e5140');
    for(let i=0;i<7;i++){
      const x=17+i*8,yy=y+8+(x-13)/2;
      c.rect(x,yy-11,5,10,['#b4ad7c','#8eaa8d','#bfaa77'][i%3]);c.line(x,yy-5,x+4,yy-3,'#e1d3a5',1);
    }
    c.line(11,y+10,81,y+45,C.woodLight,3);
  }
});
sprite('kit_counter',{w:128,h:112},c=>{
  box(c,35,69,68,29,35,'#c5b996','#8f896b','#697565');
  c.line(8,62,74,95,'#d7cba7',2);c.line(42,65,42,89,'#746f56',1);
  box(c,53,42,20,13,13,'#768c80','#405a54','#354b48');c.poly([43,25,61,34,61,43,43,34],'#a8c6ac');
});
sprite('kit_sink',{w:96,h:112},c=>{
  box(c,36,71,36,26,31,'#c9ceba','#a9bca9','#819f95');
  c.ellipse(43,51,14,6,'#dfe2ca');c.ellipse(43,51,10,4,'#859c95');c.ellipse(43,52,6,2,'#4a6661');
  c.line(46,44,46,31,'#b9cbc0',3);c.line(46,31,37,27,'#dce1cb',3);c.line(37,27,37,33,'#dce1cb',2);
  c.line(23,70,23,80,'#476960',2);
});
sprite('kit_toilet',{w:80,h:96},c=>{
  box(c,33,49,23,15,31,'#e3e1c9','#bac7b3','#89a499');
  c.ellipse(37,61,21,11,'#dae0c8');c.ellipse(37,59,18,8,'#f0edd5');c.ellipse(37,59,12,5,'#74938a');
  c.poly([26,65,48,74,44,84,30,81], '#b7c8b7');c.ellipse(38,81,12,5,'#a5baaa');
  c.line(37,25,45,29,'#869c8f',2);
});
sprite('kit_shower',{w:128,h:160},c=>{
  box(c,52,119,44,39,7,'#d4d9c3','#aabdaf','#8ba69c');
  panel(c,[16,136],[55,155],108,'#647e7760');panel(c,[55,155],[94,136],108,'#829d8c45');
  for(const [x,y]of [[16,136],[55,155],[94,136]])c.line(x,y,x,y-108,'#a8c1ac',2);
  c.line(16,28,55,47,'#cbd6bb',2);c.line(55,47,94,28,'#cbd6bb',2);c.line(57,64,57,94,'#d1d6be',3);
  c.line(38,32,38,52,'#b4c6b3',2);c.line(38,32,50,38,'#d1d6be',4);
});
sprite('kit_elevator',{w:128,h:144},c=>{
  panel(c,[17,96],[100,138],96,'#3b5350');panel(c,[23,93],[94,129],84,'#92a79b');
  c.line(58,29,58,110,'#415f57',3);c.line(25,92,94,127,'#d4d5ba',3);
  c.line(25,13,94,48,'#bbc7af',4);c.line(26,16,26,88,'#6c8d7e',2);
  panel(c,[39,16],[70,32],9,'#263e3b');c.line(48,12,59,18,'#d4b477',2);
  c.rect(103,86,7,14,'#6f8e81');c.px(106,89,'#dacb92');c.px(106,96,'#d79970');
});
for(const dir of ['up','down'])sprite(`kit_stair_${dir}`,{w:128,h:128},c=>{
  c.poly([13,87,76,119,110,102,48,70],'#344c46');
  for(let n=7;n>=0;n--){const x=47-n*4,y=dir==='up'?70+n*2-(7-n)*4:44+n*5;box(c,x,y,62,4,4,'#b7b99b','#7d927f','#5b7669');}
  c.line(108,99,77,36,'#b7c8ac',3);for(let i=0;i<4;i++)c.line(108-i*9,99-i*18,108-i*9,82-i*18,'#829e8b',2);
});
sprite('kit_exterior_canopy',{w:160,h:96},c=>{
  c.poly([13,26,115,77,149,60,47,9],'#4f7765');
  for(let i=0;i<10;i++){const x=13+i*10;c.line(x,26+i*5,x+34,9+i*5,i%2?'#799079':'#c3bc96',7);}
  panel(c,[13,26],[115,77],-8,'#7b927a');
});
sprite('kit_flashlight',{w:48,h:48},c=>{
  c.poly([9,31,28,12,36,20,17,39],'#38544e');
  c.poly([24,13,29,8,40,19,35,24],'#93aa95');
  c.poly([28,10,32,6,42,16,38,20],'#e4d8a5');
  c.line(13,29,21,21,'#7e9a85',3);c.rect(22,20,4,4,'#d5b66d');
});
sprite('kit_bandage',{w:48,h:48},c=>{
  box(c,21,23,25,17,12,'#c9d3b4','#9eb49e','#6c8c7e');
  c.poly([20,13,27,16,27,24,34,27,34,33,27,30,27,38,20,34,20,27,13,24,13,18,20,21],'#b36f55');
});
sprite('kit_breaker',{w:48,h:64},c=>{
  panel(c,[7,45],[38,60],43,'#415b55');panel(c,[11,43],[34,55],35,'#819a88');
  c.line(21,14,21,48,'#324e47',2);
  for(let i=0;i<3;i++){c.rect(14,20+i*8,5,6,'#243e37');c.rect(25,25+i*8,6,4,i===0?'#d49c68':'#aeb99a');}
});
sprite('kit_can',{w:48,h:48},c=>{
  c.poly([15,15,31,23,31,38,15,30],'#728e82');c.ellipse(23,18,9,5,'#c5cdb2');
  c.ellipse(23,18,4,2,'#425d54');c.line(17,23,29,29,'#d0b475',4);c.line(16,30,30,37,'#a3b39b',2);
});
sprite('kit_map',{w:64,h:48},c=>{
  c.poly([7,11,23,17,37,11,56,20,56,40,38,31,23,39,7,30],'#d6cfaa');
  c.line(23,17,23,39,'#a59f7f');c.line(37,11,38,31,'#a59f7f');
  c.line(11,20,48,31,'#708c7b',3);c.line(31,17,30,34,'#708c7b',3);c.rect(40,24,6,5,'#b66f4c');
});
sprite('kit_broadcast',{w:256,h:240},c=>{
  box(c,114,209,46,28,8,'#758a7d','#425e55','#2b4842');
  c.poly([108,142,129,151,129,217,108,207],'#334e49');
  c.line(113,156,113,205,'#839488',3);
  panel(c,[23,109],[220,207],105,'#263f40');
  panel(c,[32,103],[210,192],87,'#56766a');
  panel(c,[38,99],[204,182],75,'#153d45');
  c.line(27,8,215,102,'#a8b498',4);
  c.line(27,13,27,103,'#758c7d',3);
  c.line(39,97,204,179,'#83b7a3',2);
  c.line(41,34,192,109,'#2a5053',2);
  c.rect(218,177,7,9,'#d6a86c');
});
sheet('building_kit_catalog',['kit_*'],{cols:6,pad:8});
