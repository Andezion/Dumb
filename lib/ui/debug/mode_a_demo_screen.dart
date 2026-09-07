import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bitstream/bit_utils.dart';
import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_metrics.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../core/channel/received_symbol.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import '../transfer_panel/widgets/spectrum_graph.dart';

const _kDemoPattern = 'Hello phyra';

class ModeADemoScreen extends ConsumerStatefulWidget {
  const ModeADemoScreen({super.key});

  @override
  ConsumerState<ModeADemoScreen> createState() => _ModeADemoScreenState();
}

class _ModeADemoScreenState extends ConsumerState<ModeADemoScreen> {
  StreamSubscription<ReceivedSymbol>? _symbolSubscription;
  StreamSubscription<ChannelMetrics>? _metricsSubscription;
  final List<int> _receivedBits = [];
  AcousticMetrics? _latestMetrics;
  bool _isTransmitting = false;
  bool _isReceiving = false;
  String? _error;

  @override
  void dispose() {
    _symbolSubscription?.cancel();
    _metricsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _transmit() async {
    setState(() {
      _isTransmitting = true;
      _error = null;
    });
    try {
      final channel = ref.read(channelRegistryProvider).forId(ChannelId.acoustic);
      await channel.startTransmit(BitUtils.asciiToBits(_kDemoPattern), config: const {});
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  void _startReceive() {
    setState(() {
      _isReceiving = true;
      _receivedBits.clear();
      _error = null;
    });
    final channel = ref.read(channelRegistryProvider).forId(ChannelId.acoustic);
    _symbolSubscription = channel.startReceive(config: const {}).listen(
      (symbol) => setState(() => _receivedBits.add(symbol.bit)),
      onError: (Object e) => setState(() => _error = '$e'),
    );
    _metricsSubscription = channel.metrics.listen((metrics) {
      if (metrics is AcousticMetrics) setState(() => _latestMetrics = metrics);
    });
  }

  Future<void> _stopReceive() async {
    final channel = ref.read(channelRegistryProvider).forId(ChannelId.acoustic);
    await channel.stop();
    await _symbolSubscription?.cancel();
    await _metricsSubscription?.cancel();
    setState(() => _isReceiving = false);
  }

  String get _decodedText {
    if (_receivedBits.length < 8) return '';
    final bytes = BitUtils.bitsToBytes(_receivedBits);
    return String.fromCharCodes(bytes.map((b) => (b >= 32 && b < 127) ? b : 0x2E)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode A - signal demo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text('Raw bit pattern, no packet protocol', style: PhyraTextStyles.sectionLabel),
              const SizedBox(height: 16),
              PhyraPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pattern', style: PhyraTextStyles.telemetryLabel),
                    const SizedBox(height: 6),
                    const Text('"$_kDemoPattern"', style: PhyraTextStyles.telemetryValueSmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isTransmitting ? null : _transmit,
                        child: Text(_isTransmitting ? 'Transmitting...' : 'Transmit'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PhyraPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Received symbols', style: PhyraTextStyles.telemetryLabel),
                        Text('${_receivedBits.length} bits', style: PhyraTextStyles.telemetryLabel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _decodedText.isEmpty ? '-' : _decodedText,
                      style: PhyraTextStyles.telemetryValue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _receivedBits.take(64).join(),
                      style: PhyraTextStyles.telemetryLabel,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    if (_latestMetrics != null)
                      SpectrumGraph(
                        bins: _latestMetrics!.spectrumBins,
                        binFreqsHz: _latestMetrics!.binFreqsHz,
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isReceiving ? _stopReceive : _startReceive,
                        child: Text(_isReceiving ? 'Stop' : 'Receive'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
