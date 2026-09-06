sealed class TransferPhase {
  const TransferPhase();
}

class TransferIdle extends TransferPhase {
  const TransferIdle();
}

class TransferCalibrating extends TransferPhase {
  const TransferCalibrating();
}

class TransferTransmitting extends TransferPhase {
  const TransferTransmitting(this.progress);
  final double progress;
}

class TransferReceiving extends TransferPhase {
  const TransferReceiving(this.progress);
  final double progress;
}

class TransferVerifying extends TransferPhase {
  const TransferVerifying();
}

class TransferComplete extends TransferPhase {
  const TransferComplete();
}

class TransferFailed extends TransferPhase {
  const TransferFailed(this.reason);
  final String reason;
}
