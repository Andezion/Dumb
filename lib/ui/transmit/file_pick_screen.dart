import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../channel_select/channel_select_screen.dart';
import '../common/transfer_intent.dart';

class FilePickScreen extends StatefulWidget {
  const FilePickScreen({super.key});

  @override
  State<FilePickScreen> createState() => _FilePickScreenState();
}

class _FilePickScreenState extends State<FilePickScreen> {
  String? _error;

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final result = await FilePicker.pickFiles(withData: false);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChannelSelectScreen(intent: TransferIntent.transmit, file: file),
        ),
      );
    } catch (e) {
      setState(() => _error = 'File selection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a file')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a file to transmit', style: PhyraTextStyles.sectionLabel),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: _pickFile, child: const Text('Browse files')),
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
