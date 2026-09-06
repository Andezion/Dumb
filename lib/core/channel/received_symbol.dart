class ReceivedSymbol {
  const ReceivedSymbol({required this.bit, required this.confidence, required this.timestampUs});

  final int bit;
  final double confidence;
  final int timestampUs;
}
