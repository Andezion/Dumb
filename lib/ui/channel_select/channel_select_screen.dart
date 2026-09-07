import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/channel/channel_id.dart';
import '../../theme/phyra_text_styles.dart';
import '../calibrate/calibrate_screen.dart';
import '../common/transfer_intent.dart';
import 'channel_card.dart';

class ChannelSelectScreen extends StatelessWidget {
  const ChannelSelectScreen({super.key, required this.intent, this.file});

  final TransferIntent intent;

  final File? file;

  void _selectChannel(BuildContext context, ChannelId id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalibrateScreen(intent: intent, channelId: id, file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a channel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Select a way to send data',
              style: PhyraTextStyles.sectionLabel,
            ),
            const SizedBox(height: 16),
            for (final id in ChannelId.values) ...[
              ChannelCard(channelId: id, onTap: () => _selectChannel(context, id)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
