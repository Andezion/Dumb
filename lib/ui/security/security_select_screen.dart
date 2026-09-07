import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/channel/channel_id.dart';
import '../../core/compression/codec_id.dart';
import '../../core/crypto/cipher_id.dart';
import '../../core/security/security_config.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../calibrate/calibrate_screen.dart';
import '../common/transfer_intent.dart';

class SecuritySelectScreen extends StatefulWidget {
  const SecuritySelectScreen({super.key, required this.intent, required this.channelId, this.file});

  final TransferIntent intent;
  final ChannelId channelId;
  final File? file;

  @override
  State<SecuritySelectScreen> createState() => _SecuritySelectScreenState();
}

class _SecuritySelectScreenState extends State<SecuritySelectScreen> {
  CipherId _cipherId = CipherId.chacha20;
  CodecId _codecId = CodecId.huffman;
  final _passphraseController = TextEditingController();

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalibrateScreen(
          intent: widget.intent,
          channelId: widget.channelId,
          file: widget.file,
          security: SecurityConfig(
            cipherId: _cipherId,
            codecId: _codecId,
            passphrase: _passphraseController.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Nothing here is sent over the channel - both devices must be set '
              'to the same cipher, compression, and passphrase in advance.',
              style: PhyraTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text('Shared password', style: PhyraTextStyles.sectionLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _passphraseController,
              obscureText: true,
              style: PhyraTextStyles.telemetryValueSmall,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: PhyraColors.darkGray),
                ),
                hintText: 'Must match on both devices',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Cipher', style: PhyraTextStyles.sectionLabel),
            const SizedBox(height: 8),
            for (final id in CipherId.values) ...[
              _OptionTile(
                title: id.title,
                description: id.description,
                selected: id == _cipherId,
                onTap: () => setState(() => _cipherId = id),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Text('Compression', style: PhyraTextStyles.sectionLabel),
            const SizedBox(height: 8),
            for (final id in CodecId.values) ...[
              _OptionTile(
                title: id.title,
                description: id.description,
                selected: id == _codecId,
                onTap: () => setState(() => _codecId = id),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _passphraseController.text.isNotEmpty ? () => _continue(context) : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
