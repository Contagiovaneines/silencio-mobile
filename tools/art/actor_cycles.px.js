// Offline complete-frame animation. No torso/leg slicing occurs at runtime.
// Foot pivot is (64,119); gait phase is selected by distance in the game.
include('actor_skins.px.js');
const actorStates={idle:4,walk:8,run:8,attack:8,guard:4,hurt:6,guard_walk:8};
function pose(c,skin,dir,state,frame,count,ox,oy,name){
  const phase=frame/count*Math.PI*2, t=frame/(count-1), moving=state==='walk'||state==='run'||state==='guard_walk';
  const axis=[Math.cos(dir*Math.PI/4),Math.sin(dir*Math.PI/4)*.48];
  const step=moving?Math.sin(phase):0, stride=state==='run'?19:14;
  const hit=state==='attack'?Math.sin(t*Math.PI):0;
  const hurt=state==='hurt'?Math.sin(t*Math.PI):0;
  const bob=moving?-Math.abs(Math.sin(phase*2))*(state==='run'?1.8:.7):-Math.sin(phase)*1.4;
  function warp(x,sy){
    let px=x,py=sy;
    const side=x<64?-1:1;
    const hem=name==='ines'?109:88;
    if(sy>=hem){
      const blend=Math.min(1,(sy-hem)/(119-hem)),swing=step*side;
      px+=axis[0]*swing*stride*blend;
      py+=axis[1]*swing*stride*blend-Math.max(0,swing)*(state==='run'?4:2)*blend;
      if(moving&&sy>110)py-=Math.max(0,Math.cos(phase)*side)*.7;
    }else{
      px+=axis[0]*hit*2-axis[0]*hurt*3;
      py+=(bob+Math.sin(phase)*.3)*Math.min(1,(hem-sy)/12)-axis[1]*hurt*2;
      const arm=name!=='caio'&&sy>48&&sy<88&&(x<54||x>74);
      if(arm){
        const edge=Math.min(1,x<54?(54-x)/8:(x-74)/8);
        const reach=Math.max(0,(sy-48)/40)*edge;
        if(state==='guard'){px-=side*reach*2;py-=reach*5;}
        else if(state==='attack'){px+=axis[0]*hit*reach*4;py+=axis[1]*hit*reach*4-reach*hit*3;}
        else if(state==='hurt'){px+=side*hurt*reach*4;py-=hurt*reach*5;}
        else if(moving){px-=axis[0]*step*side*reach*2.5;py-=axis[1]*step*side*reach*3;}
      }
    }
    return [ox+px,oy+py];
  }
  for(const [sx,sy,length,color] of skin)for(let x=sx;x<sx+length;x+=2){
    const end=Math.min(x+2,sx+length);
    // Map complete pixel quads, so stretched limbs never leave raster holes.
    c.poly([...warp(x,sy),...warp(end,sy),...warp(end,sy+1),...warp(x,sy+1)],color);
  }
}
for(const [name,directions] of Object.entries(actorSkins))for(const [state,defaultCount]of Object.entries(actorStates)){
  if(state==='guard_walk'&&!name.startsWith('caio'))continue;
  const count=name.startsWith('caio')&&(state==='walk'||state==='run')?6:defaultCount;
  sprite(`actor_${name}_${state}`,{w:128*count,h:144*8},c=>{
    for(let dir=0;dir<8;dir++)for(let f=0;f<count;f++){
      const poses=modularActionSkins[name]?.[state==='guard_walk'?'guard':state]?.[dir]??(name==='caio'?caioActionSkins[state==='guard_walk'?'guard':state]?.[dir]:name==='davi'&&(dir<5||state==='attack'||state==='guard')?daviActionSkins[state]?.[dir]:null);
      const authored=modularLocomotionSkins[name]?.[state]?.[dir]?.[f]??(name==='caio'?caioLocomotionSkins[state]?.[dir]?.[f]:null);
      if(authored){for(const [x,y,n,color]of authored)c.rect(f*128+x,dir*144+y,n,1,color);continue;}
      const skin=poses?poses[Math.min(poses.length-1,Math.floor(f/count*poses.length))]:directions[dir];
      pose(c,skin,dir,state,f,count,f*128,dir*144,name);
    }
  });
}
