import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/channel/channel_id.dart';
import '../../platform/mechanical_config.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/transfer_intent.dart';
import '../security/security_select_screen.dart';

class MechanicalModeScreen extends ConsumerWidget {
  const MechanicalModeScreen({super.key, required this.intent, this.file});

  final TransferIntent intent;
  final File? file;

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecuritySelectScreen(intent: intent, channelId: ChannelId.mechanical, file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(mechanicalConfigProvider);
    final notifier = ref.read(mechanicalConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Mechanical mode')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vibration -> Surface -> Accelerometer', style: PhyraTextStyles.sectionLabel),
              const SizedBox(height: 16),
              for (final mode in MechanicalMode.values) ...[
                _ModeTile(
                  title: mode.title,
                  description: mode.description,
                  selected: mode == config.mode,
                  onTap: () => notifier.state = config.copyWith(mode: mode),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _continue(context),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PhyraColors.nearBlack,
          border: Border.all(color: selected ? PhyraColors.white : PhyraColors.darkGray),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? PhyraColors.white : PhyraColors.mediumGray,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PhyraTextStyles.buttonLabel),
                  const SizedBox(height: 4),
                  Text(description, style: PhyraTextStyles.telemetryLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
