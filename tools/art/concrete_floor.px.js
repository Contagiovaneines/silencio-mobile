// Original SILÊNCIO concrete tile variations.
// Keep every mark low-contrast, inside a 64x32 isometric footprint and tied to
// a plausible surface feature (joint, moisture, hairline crack or leaf).

const base = '#7a8281';
const light = '#909997';
const shade = '#626b69';
const deep = '#596260';
const debris = '#918774';

sprite('tile_concrete_0', {w:64,h:32}, (c) => {
  c.poly([32,0,63,16,32,31,0,16], base);
  c.line(16, 12, 22, 15, light, 2);
  c.line(22, 15, 29, 12, light, 2);
  c.line(41, 20, 48, 17, shade, 2);
});

sprite('tile_concrete_1', {w:64,h:32}, (c) => {
  c.poly([32,0,63,16,32,31,0,16], base);
  c.ellipse(26, 16, 10, 4, shade);
  c.ellipse(27, 15, 6, 3, deep);
  c.line(43, 18, 49, 16, light, 2);
});

sprite('tile_concrete_2', {w:64,h:32}, (c) => {
  c.poly([32,0,63,16,32,31,0,16], base);
  c.line(38, 9, 33, 14, deep, 2);
  c.line(33, 14, 37, 17, deep, 2);
  c.line(37, 17, 30, 22, deep, 2);
  c.line(18, 18, 22, 16, light, 2);
});

sprite('tile_concrete_3', {w:64,h:32}, (c) => {
  c.poly([32,0,63,16,32,31,0,16], base);
  c.ellipse(43, 16, 3, 2, debris);
  c.ellipse(47, 18, 2, 1, shade);
  c.ellipse(40, 19, 2, 1, light);
  c.line(17, 10, 23, 13, shade, 2);
});
