class TransferStatistics {
  TransferStatistics({
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.crcErrors = 0,
    this.resyncCount = 0,
    this.bytesTransferred = 0,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final int packetsSent;
  final int packetsReceived;
  final int crcErrors;
  final int resyncCount;
  final int bytesTransferred;
  final DateTime startedAt;

  Duration get elapsed => DateTime.now().difference(startedAt);

  double get rateBytesPerSec {
    final seconds = elapsed.inMilliseconds / 1000.0;
    return seconds <= 0 ? 0 : bytesTransferred / seconds;
  }

  TransferStatistics copyWith({
    int? packetsSent,
    int? packetsReceived,
    int? crcErrors,
    int? resyncCount,
    int? bytesTransferred,
  }) {
    return TransferStatistics(
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      crcErrors: crcErrors ?? this.crcErrors,
      resyncCount: resyncCount ?? this.resyncCount,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      startedAt: startedAt,
    );
  }
}
