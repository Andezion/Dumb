class ChannelCapabilities {
  const ChannelCapabilities({required this.hardwareAvailable, this.unavailableReason});

  final bool hardwareAvailable;
  final String? unavailableReason;
}
