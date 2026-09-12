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

enum OpticalRole { idle, searching, locked, transmitting }

class OpticalMetrics extends ChannelMetrics {
  const OpticalMetrics({
    required this.cells,
    required this.rows,
    required this.cols,
    required this.role,
    required this.confidence,
    this.frameIndex,
    this.framesLocked = 0,
    this.frameCrcErrors = 0,
  });

  final List<bool> cells;
  final int rows;
  final int cols;
  final OpticalRole role;
  final double confidence;
  final int? frameIndex;
  final int framesLocked;
  final int frameCrcErrors;
}
