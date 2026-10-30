// Original icon for the wooden club Caio can pick up near the alley.
// Match the project's muted, readable pixel-art palette at phone scale.
sprite('item_weapon', {w:32,h:32}, (c) => {
  c.ellipse(17, 28, 10, 2, '#172024');
  c.line(7, 26, 22, 11, '#4d3728', 7);
  c.line(7, 25, 22, 10, '#a8794d', 3);
  c.poly([17,8,20,3,28,7,26,15,21,17], '#513a2a');
  c.poly([19,8,22,5,26,8,24,13,21,14], '#c09361');
  c.line(9, 25, 13, 21, '#d1a06c', 1);
});
