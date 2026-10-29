// Original installation probe; not a production asset.
pal({k:"#141b25",g:"#b5c6ce",G:"#617681",a:"#d8b16b"})
sprite("chave_teste", {w:24,h:16,outline:"k"},
  ring(6,7,4,"a"), rect(9,6,11,3,"a"), rect(16,8,2,3,"a"), rect(19,8,2,3,"a"))
anim("passos_teste", {w:24,h:32,frames:6,fps:8}, (c)=>{
  const swing=Math.round(Math.sin(c.phase*Math.PI*2)*3);
  c.rect(8,4,8,7,"g"); c.rect(7,11,10,10,"G");
  c.rect(8+swing,21,3,8,"g"); c.rect(13-swing,21,3,8,"g");
  c.rect(7+swing,28,5,3,"k"); c.rect(12-swing,28,5,3,"k");
})
sheet("qa_sheet", ["chave_teste"], {pad:1})
