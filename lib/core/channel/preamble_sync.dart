abstract final class PreambleSync {
  static const List<int> preambleBits = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1];
  static const List<int> syncWordBits = [1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0];

  static List<int> header() => [...preambleBits, ...syncWordBits];

  static int hammingDistance(List<int> a, List<int> b) {
    assert(a.length == b.length, 'hammingDistance requires equal-length lists');
    var count = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) count++;
    }
    return count;
  }
}
