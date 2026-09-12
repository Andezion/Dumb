import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../core/security/security_config.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import '../common/transfer_intent.dart';
import '../transfer_panel/transfer_instrument_panel_screen.dart';

class CalibrateScreen extends ConsumerStatefulWidget {
  const CalibrateScreen({
    super.key,
    required this.intent,
    required this.channelId,
    required this.security,
    this.file,
  });

  final TransferIntent intent;
  final ChannelId channelId;
  final SecurityConfig security;
  final File? file;

  @override
  ConsumerState<CalibrateScreen> createState() => _CalibrateScreenState();
}

class _CalibrateScreenState extends ConsumerState<CalibrateScreen> {
  late final Future<Map<String, double>> _calibrationFuture;

  @override
  void initState() {
    super.initState();
    _calibrationFuture = _runCalibration();
  }

  Future<Map<String, double>> _runCalibration() async {
    if (widget.channelId == ChannelId.acoustic) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw StateError('Microphone permission denied');
      }
    }
    if (widget.channelId == ChannelId.optical) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw StateError('Camera permission denied');
      }
    }
    return ref.read(channelRegistryProvider).forId(widget.channelId).calibrate();
  }

  Future<void> _proceed(BuildContext context) async {
    Directory? saveDirectory;
    if (widget.intent == TransferIntent.receive) {
      saveDirectory = await getApplicationDocumentsDirectory();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransferInstrumentPanelScreen(
          intent: widget.intent,
          channelId: widget.channelId,
          security: widget.security,
          file: widget.file,
          saveDirectory: saveDirectory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibration')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.channelId.title} * Baseline measurment', style: PhyraTextStyles.sectionLabel),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<Map<String, double>>(
                  future: _calibrationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: PhyraColors.lightGray),
                            SizedBox(height: 16),
                            Text('Measuring baseline...', style: PhyraTextStyles.telemetryLabel),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Calibration failed\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure),
                        ),
                      );
                    }
                    final values = snapshot.data!;
                    return PhyraPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Calibration complete', style: PhyraTextStyles.telemetryLabel),
                          const SizedBox(height: 12),
                          for (final entry in values.entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key, style: PhyraTextStyles.telemetryLabel),
                                  Text(entry.value.toStringAsFixed(1), style: PhyraTextStyles.telemetryValueSmall),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              FutureBuilder<Map<String, double>>(
                future: _calibrationFuture,
                builder: (context, snapshot) {
                  final ready = snapshot.connectionState == ConnectionState.done && !snapshot.hasError;
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: ready ? () => _proceed(context) : null,
                      child: Text(widget.intent == TransferIntent.transmit ? 'Start transmission' : 'Wait for signal'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
