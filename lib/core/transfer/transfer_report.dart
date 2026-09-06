import '../channel/channel_id.dart';

class TransferReport {
  const TransferReport({
    required this.channel,
    required this.fileName,
    required this.sizeBytes,
    required this.duration,
    required this.averageRateBytesPerSec,
    required this.packetsSent,
    required this.packetsReceived,
    required this.packetErrors,
    required this.verified,
    this.filePath,
  });

  final ChannelId channel;
  final String fileName;
  final int sizeBytes;
  final Duration duration;
  final double averageRateBytesPerSec;
  final int packetsSent;
  final int packetsReceived;
  final int packetErrors;
  final bool? verified;

  final String? filePath;
}
