import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../capability/capability_provider.dart';
import '../common/phyra_panel.dart';

class ChannelCard extends ConsumerWidget {
  const ChannelCard({super.key, required this.channelId, required this.onTap});

  final ChannelId channelId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImplemented = ref.read(channelRegistryProvider).isImplemented(channelId);
    final capabilityAsync = ref.watch(channelCapabilitiesProvider(channelId));

    final hardwareAvailable = capabilityAsync.asData?.value.hardwareAvailable ?? false;
    final enabled = isImplemented && hardwareAvailable;

    String statusLabel;
    if (!isImplemented) {
      statusLabel = 'Not yet implemented';
    } else if (capabilityAsync.isLoading) {
      statusLabel = 'Checking hardware...';
    } else if (!hardwareAvailable) {
      statusLabel = capabilityAsync.asData?.value.unavailableReason?.toUpperCase() ?? 'Hardware unavailable';
    } else {
      statusLabel = 'Ready';
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: PhyraPanel(
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(channelId.glyph, style: PhyraTextStyles.title.copyWith(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channelId.title, style: PhyraTextStyles.buttonLabel),
                    const SizedBox(height: 4),
                    Text(channelId.physicalChain, style: PhyraTextStyles.telemetryLabel),
                    const SizedBox(height: 6),
                    Text(
                      statusLabel,
                      style: PhyraTextStyles.telemetryLabel.copyWith(
                        color: enabled ? PhyraColors.success : PhyraColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
