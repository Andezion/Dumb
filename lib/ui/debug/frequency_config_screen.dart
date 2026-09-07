import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/acoustic_config.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';

class FrequencyConfigScreen extends ConsumerWidget {
  const FrequencyConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(acousticConfigProvider);
    final notifier = ref.read(acousticConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Acoustic frequency configuration')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Must match on both devices',
                style: PhyraTextStyles.sectionLabel,
              ),
              const SizedBox(height: 20),
              PhyraPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _slider(
                      label: 'Freq 0 (symbol 0)',
                      valueHz: config.freq0Hz,
                      min: 1000,
                      max: 10000,
                      onChanged: (v) => notifier.state = config.copyWith(freq0Hz: v),
                    ),
                    const SizedBox(height: 20),
                    _slider(
                      label: 'Freq 1 (symbol 1)',
                      valueHz: config.freq1Hz,
                      min: 1000,
                      max: 10000,
                      onChanged: (v) => notifier.state = config.copyWith(freq1Hz: v),
                    ),
                    const SizedBox(height: 20),
                    _slider(
                      label: 'Symbol duration (ms)',
                      valueHz: config.symbolDurationMs,
                      min: 10,
                      max: 100,
                      onChanged: (v) => notifier.state = config.copyWith(symbolDurationMs: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => notifier.state = const AcousticConfig(),
                child: const Text('Reset to defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required int valueHz,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: PhyraTextStyles.telemetryLabel),
            Text('$valueHz', style: PhyraTextStyles.telemetryValueSmall),
          ],
        ),
        Slider(
          value: valueHz.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
