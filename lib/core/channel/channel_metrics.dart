sealed class ChannelMetrics {
  const ChannelMetrics();
}

enum AcousticLinkState { idle, listening, locked }

class AcousticMetrics extends ChannelMetrics {
  const AcousticMetrics({
    required this.spectrumBins,
    required this.binFreqsHz,
    required this.signalLevel,
    required this.detectedSymbol,
    required this.confidence,
    required this.state,
  });

  final List<double> spectrumBins;
  final List<int> binFreqsHz;
  final double signalLevel;
  final int? detectedSymbol;
  final double confidence;
  final AcousticLinkState state;
}
