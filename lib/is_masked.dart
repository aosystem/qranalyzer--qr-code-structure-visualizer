bool isMasked(int maskPattern, int x, int y) {
  switch (maskPattern) {
    case 0:
      return (y + x) % 2 == 0;
    case 1:
      return y % 2 == 0;
    case 2:
      return x % 3 == 0;
    case 3:
      return (y + x) % 3 == 0;
    case 4:
      return ((y ~/ 2) + (x ~/ 3)) % 2 == 0;
    case 5:
      return ((y * x) % 2 + (y * x) % 3) == 0;
    case 6:
      return (((y * x) % 2) + ((y * x) % 3)) % 2 == 0;
    case 7:
      return (((y + x) % 2) + ((y * x) % 3)) % 2 == 0;
    default:
      return false;
  }
}
