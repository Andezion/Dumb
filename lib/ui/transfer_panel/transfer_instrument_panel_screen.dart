import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_metrics.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../core/security/security_config.dart';
import '../../core/transfer/transfer_manager_provider.dart';
import '../../core/transfer/transfer_state.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import '../common/transfer_intent.dart';
import '../transfer_report/transfer_report_screen.dart';
import 'widgets/metric_tile.dart';
import 'widgets/packet_counter_tile.dart';
import 'widgets/signal_meter.dart';
import 'widgets/spectrum_graph.dart';

class TransferInstrumentPanelScreen extends ConsumerStatefulWidget {
  const TransferInstrumentPanelScreen({
    super.key,
    required this.intent,
    required this.channelId,
    required this.security,
    this.file,
    this.saveDirectory,
  });

  final TransferIntent intent;
  final ChannelId channelId;
  final SecurityConfig security;
  final File? file;
  final Directory? saveDirectory;

  @override
  ConsumerState<TransferInstrumentPanelScreen> createState() => _TransferInstrumentPanelScreenState();
}

class _TransferInstrumentPanelScreenState extends ConsumerState<TransferInstrumentPanelScreen> {
  StreamSubscription<ChannelMetrics>? _metricsSubscription;
  AcousticMetrics? _latestAcousticMetrics;
  bool _navigatedToReport = false;

  @override
  void initState() {
    super.initState();
    final channel = ref.read(channelRegistryProvider).forId(widget.channelId);
    _metricsSubscription = channel.metrics.listen((metrics) {
      if (metrics is AcousticMetrics && mounted) {
        setState(() => _latestAcousticMetrics = metrics);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final manager = ref.read(transferManagerProvider.notifier);
      if (widget.intent == TransferIntent.transmit) {
        manager.startTransmit(channelId: widget.channelId, file: widget.file!, security: widget.security);
      } else {
        manager.startReceiveFile(
          channelId: widget.channelId,
          saveDirectory: widget.saveDirectory!,
          security: widget.security,
        );
      }
    });
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    await ref.read(transferManagerProvider.notifier).cancel();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(transferManagerProvider);
    final phase = managerState.phase;

    ref.listen(transferManagerProvider, (previous, next) {
      if (next.phase is TransferComplete && next.report != null && !_navigatedToReport) {
        _navigatedToReport = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TransferReportScreen(report: next.report!)),
        );
      }
    });

    final modeLabel = switch (phase) {
      TransferIdle() => 'IDLE',
      TransferCalibrating() => 'CALIBRATING',
      TransferTransmitting() => 'TRANSMITTING',
      TransferReceiving() => 'RECEIVING',
      TransferVerifying() => 'VERIFYING',
      TransferComplete() => 'COMPLETE',
      TransferFailed() => 'FAILED',
    };

    final stats = managerState.statistics;
    final signalLevel = _latestAcousticMetrics?.signalLevel ?? 0.0;
    final symbolLabel = _latestAcousticMetrics?.detectedSymbol?.toString() ?? '—';
    final progress = switch (phase) {
      TransferTransmitting(:final progress) => progress,
      TransferReceiving(:final progress) => progress,
      TransferComplete() => 1.0,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Instrument panel')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Channel', style: PhyraTextStyles.telemetryLabel),
              Text(widget.channelId.title, style: PhyraTextStyles.title.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Mode  $modeLabel', style: PhyraTextStyles.sectionLabel),
              if (progress != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: PhyraColors.darkGray,
                          valueColor: const AlwaysStoppedAnimation(PhyraColors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                      style: PhyraTextStyles.telemetryLabel,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              PhyraPanel(child: SignalMeter(level: signalLevel)),
              const SizedBox(height: 16),
              if (_latestAcousticMetrics != null)
                PhyraPanel(
                  child: SpectrumGraph(
                    bins: _latestAcousticMetrics!.spectrumBins,
                    binFreqsHz: _latestAcousticMetrics!.binFreqsHz,
                  ),
                ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  MetricTile(label: 'Symbol', value: symbolLabel),
                  PacketCounterTile(
                    count: widget.intent == TransferIntent.transmit ? stats.packetsSent : stats.packetsReceived,
                    total: null,
                  ),
                  MetricTile(label: 'Data', value: _formatBytes(stats.bytesTransferred)),
                  MetricTile(label: 'Rate', value: '${(stats.rateBytesPerSec).toStringAsFixed(1)} B/s'),
                  MetricTile(
                    label: 'Errors',
                    value: 'Crc: ${stats.crcErrors}',
                    valueColor: stats.crcErrors > 0 ? PhyraColors.warning : PhyraColors.white,
                  ),
                  MetricTile(
                    label: 'Integrity',
                    value: phase is TransferComplete ? 'Done' : 'Pending',
                  ),
                ],
              ),
              if (phase is TransferFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    phase.reason,
                    style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (phase is TransferComplete || phase is TransferFailed) ? null : _stop,
                  child: const Text('Stop'),
                ),
              ),
              if (phase is TransferFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('Back to home'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
