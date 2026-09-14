import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_metrics.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../core/security/security_config.dart';
import '../../core/transfer/transfer_manager_provider.dart';
import '../../core/transfer/transfer_state.dart';
import '../../platform/optical/optical_channel.dart';
import '../../platform/optical/optical_grid_frame.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import '../common/transfer_intent.dart';
import '../transfer_report/transfer_report_screen.dart';
import 'widgets/metric_tile.dart';
import 'widgets/optical_grid_view.dart';
import 'widgets/packet_counter_tile.dart';
import 'widgets/signal_meter.dart';
import 'widgets/spectrum_graph.dart';
import 'widgets/waveform_graph.dart';

const _kWaveformHistoryLength = 60;

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
  OpticalMetrics? _latestOpticalMetrics;
  MechanicalMetrics? _latestMechanicalMetrics;
  MagneticMetrics? _latestMagneticMetrics;
  LightMetrics? _latestLightMetrics;
  final List<double> _mechanicalHistory = [];
  final List<double> _magneticHistory = [];
  final List<double> _lightHistory = [];
  bool _navigatedToReport = false;

  @override
  void initState() {
    super.initState();
    final channel = ref.read(channelRegistryProvider).forId(widget.channelId);
    _metricsSubscription = channel.metrics.listen((metrics) {
      if (!mounted) return;
      if (metrics is AcousticMetrics) {
        setState(() => _latestAcousticMetrics = metrics);
      } else if (metrics is OpticalMetrics) {
        setState(() => _latestOpticalMetrics = metrics);
      } else if (metrics is MechanicalMetrics) {
        setState(() {
          _latestMechanicalMetrics = metrics;
          _mechanicalHistory.add(metrics.accelerationMagnitude);
          if (_mechanicalHistory.length > _kWaveformHistoryLength) _mechanicalHistory.removeAt(0);
        });
      } else if (metrics is MagneticMetrics) {
        setState(() {
          _latestMagneticMetrics = metrics;
          _magneticHistory.add(metrics.fieldMagnitudeMicroTesla);
          if (_magneticHistory.length > _kWaveformHistoryLength) _magneticHistory.removeAt(0);
        });
      } else if (metrics is LightMetrics) {
        setState(() {
          _latestLightMetrics = metrics;
          _lightHistory.add(metrics.luxLevel);
          if (_lightHistory.length > _kWaveformHistoryLength) _lightHistory.removeAt(0);
        });
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
    final signalLevel = _latestAcousticMetrics?.signalLevel ??
        _latestOpticalMetrics?.confidence ??
        _latestMechanicalMetrics?.confidence ??
        _latestMagneticMetrics?.confidence ??
        _latestLightMetrics?.confidence ??
        0.0;
    final symbolLabel = _latestAcousticMetrics?.detectedSymbol?.toString() ??
        _latestMechanicalMetrics?.detectedSymbol?.toString() ??
        _latestMagneticMetrics?.detectedSymbol?.toString() ??
        _latestLightMetrics?.detectedSymbol?.toString() ??
        '—';
    final isOptical = widget.channelId == ChannelId.optical;
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
              if (isOptical)
                Expanded(flex: 3, child: _OpticalPanel(intent: widget.intent, metrics: _latestOpticalMetrics))
              else ...[
                PhyraPanel(child: SignalMeter(level: signalLevel)),
                const SizedBox(height: 16),
                if (_latestAcousticMetrics != null)
                  PhyraPanel(
                    child: SpectrumGraph(
                      bins: _latestAcousticMetrics!.spectrumBins,
                      binFreqsHz: _latestAcousticMetrics!.binFreqsHz,
                    ),
                  )
                else if (_latestMechanicalMetrics != null)
                  PhyraPanel(
                    child: WaveformGraph(
                      label: 'Acceleration',
                      samples: _mechanicalHistory,
                      maxValue: _latestMechanicalMetrics!.thresholdMagnitude * 2,
                    ),
                  )
                else if (_latestMagneticMetrics != null)
                  PhyraPanel(
                    child: WaveformGraph(
                      label: 'Magnetic field',
                      samples: _magneticHistory,
                      maxValue: _latestMagneticMetrics!.thresholdMicroTesla * 2,
                    ),
                  )
                else if (_latestLightMetrics != null)
                  PhyraPanel(
                    child: WaveformGraph(
                      label: 'Ambient light',
                      samples: _lightHistory,
                      maxValue: _latestLightMetrics!.thresholdLux * 2,
                    ),
                  ),
              ],
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

class _OpticalPanel extends ConsumerWidget {
  const _OpticalPanel({required this.intent, required this.metrics});

  final TransferIntent intent;
  final OpticalMetrics? metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return intent == TransferIntent.transmit ? _buildTransmit() : _buildReceive(ref);
  }

  Widget _buildTransmit() {
    final cells = metrics?.cells ?? List<bool>.filled(OpticalGridFrame.cellCount, false);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: OpticalGridView(cells: cells, rows: OpticalGridFrame.rows, cols: OpticalGridFrame.cols),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          metrics == null ? 'Waiting to start' : 'Frame ${metrics!.frameIndex}',
          style: PhyraTextStyles.telemetryLabel,
        ),
      ],
    );
  }

  Widget _buildReceive(WidgetRef ref) {
    final channel = ref.read(channelRegistryProvider).forId(ChannelId.optical);
    final controller = channel is OpticalChannel ? channel.previewController : null;
    final initialized = controller != null && controller.value.isInitialized;

    return Column(
      children: [
        Expanded(
          child: initialized
              ? Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller),
                        OpticalViewfinderOverlay(cols: OpticalGridFrame.cols, rows: OpticalGridFrame.rows),
                      ],
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator(color: PhyraColors.lightGray)),
        ),
        const SizedBox(height: 8),
        Text(_roleLabel(metrics?.role), style: PhyraTextStyles.telemetryLabel),
        if (metrics != null) ...[
          const SizedBox(height: 4),
          Text(
            'Frames locked ${metrics!.framesLocked} - Frame CRC errors ${metrics!.frameCrcErrors}',
            style: PhyraTextStyles.telemetryLabel,
          ),
        ],
      ],
    );
  }

  String _roleLabel(OpticalRole? role) => switch (role) {
        null || OpticalRole.idle => 'No signal - align camera with screen',
        OpticalRole.searching => 'Searching for sync',
        OpticalRole.locked => 'Sync locked',
        OpticalRole.transmitting => 'Transmitting',
      };
}
