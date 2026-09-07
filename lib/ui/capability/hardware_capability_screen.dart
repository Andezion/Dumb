import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import 'capability_provider.dart';

const _kSensorLabels = {
  'speaker': 'SPEAKER',
  'microphone': 'MICROPHONE',
  'accelerometer': 'ACCELEROMETER',
  'magnetometer': 'MAGNETOMETER',
  'camera': 'CAMERA',
  'flash': 'FLASH',
  'ambientLight': 'AMBIENT LIGHT',
};

class HardwareCapabilityScreen extends ConsumerWidget {
  const HardwareCapabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(hardwareInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hardware')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: inventoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: PhyraColors.lightGray)),
            error: (error, _) => Center(
              child: Text(
                'Unable to query hardware\n$error',
                textAlign: TextAlign.center,
                style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure),
              ),
            ),
            data: (inventory) => PhyraPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in _kSensorLabels.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.value, style: PhyraTextStyles.telemetryLabel),
                          Text(
                            (inventory[entry.key] ?? false) ? 'Available' : 'Not available',
                            style: PhyraTextStyles.telemetryValueSmall.copyWith(
                              color: (inventory[entry.key] ?? false) ? PhyraColors.success : PhyraColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
