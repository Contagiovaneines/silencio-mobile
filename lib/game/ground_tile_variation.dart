abstract final class ConcreteTileVariation {
  static const count = 4;

  static int at(int x, int y) {
    // Mix both coordinates before taking the high bits. Low-bit coordinate
    // formulas create visible stripes because tile indices repeat in patterns.
    var hash = ((x * 0x45d9f3b) ^ (y * 0x45d9f3b)) & 0xffffffff;
    hash = (((hash ^ (hash >>> 16)) * 0x45d9f3b) & 0xffffffff);
    hash = (((hash ^ (hash >>> 16)) * 0x45d9f3b) & 0xffffffff);
    hash = (hash ^ (hash >>> 16)) & 0xffffffff;
    return hash >>> 30;
  }
}
