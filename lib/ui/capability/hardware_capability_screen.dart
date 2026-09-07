import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _PermissionsPanel(),
            const SizedBox(height: 20),
            Text('Sensors & Actuators', style: PhyraTextStyles.telemetryLabel),
            const SizedBox(height: 8),
            inventoryAsync.when(
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
          ],
        ),
      ),
    );
  }
}

class _PermissionsPanel extends ConsumerWidget {
  const _PermissionsPanel();

  String _label(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.provisional:
        return 'Provisional';
      case PermissionStatus.denied:
        return 'Not granted';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(microphonePermissionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Permissions', style: PhyraTextStyles.telemetryLabel),
        const SizedBox(height: 8),
        PhyraPanel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Microphone access', style: PhyraTextStyles.telemetryLabel),
                    const SizedBox(height: 4),
                    permissionAsync.when(
                      loading: () => const Text('Checking...', style: PhyraTextStyles.telemetryValueSmall),
                      error: (error, _) => Text(
                        'Unavailable',
                        style: PhyraTextStyles.telemetryValueSmall.copyWith(color: PhyraColors.failure),
                      ),
                      data: (status) => Text(
                        _label(status),
                        style: PhyraTextStyles.telemetryValueSmall.copyWith(
                          color: status.isGranted ? PhyraColors.success : PhyraColors.mediumGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              permissionAsync.maybeWhen(
                data: (status) {
                  if (status.isGranted) return const SizedBox.shrink();
                  final controller = ref.read(microphonePermissionProvider.notifier);
                  if (status.isPermanentlyDenied) {
                    return OutlinedButton(
                      onPressed: () async {
                        await openAppSettings();
                        await controller.refresh();
                      },
                      child: const Text('Open settings'),
                    );
                  }
                  return OutlinedButton(
                    onPressed: controller.request,
                    child: const Text('Grant access'),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
