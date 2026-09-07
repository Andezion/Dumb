import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/channel/channel_id.dart';
import '../../core/transfer/transfer_report.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';

class TransferReportScreen extends StatefulWidget {
  const TransferReportScreen({super.key, required this.report});

  final TransferReport report;

  @override
  State<TransferReportScreen> createState() => _TransferReportScreenState();
}

class _TransferReportScreenState extends State<TransferReportScreen> {
  String? _saveError;

  Future<void> _saveFile() async {
    setState(() => _saveError = null);
    try {
      final bytes = await File(widget.report.filePath!).readAsBytes();
      await FilePicker.saveFile(fileName: widget.report.fileName, bytes: bytes);
    } catch (e) {
      setState(() => _saveError = 'Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final verified = report.verified;
    final verificationLabel = verified == null
        ? 'Not applicable (no ack channel)'
        : (verified ? 'Success - Hash match' : 'Failed - Hash mismatch');
    final verificationColor = verified == null
        ? PhyraColors.mediumGray
        : (verified ? PhyraColors.success : PhyraColors.failure);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer report')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PhyraPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Channel', report.channel.title),
                    _row('File', report.fileName),
                    _row('Size', _formatBytes(report.sizeBytes)),
                    _row('Duration', _formatDuration(report.duration)),
                    _row('Average rate', '${report.averageRateBytesPerSec.toStringAsFixed(1)} B/s'),
                    if (report.packetsSent > 0) _row('Packets sent', '${report.packetsSent}'),
                    if (report.packetsReceived > 0) _row('Packets received', '${report.packetsReceived}'),
                    _row('Packet errors', '${report.packetErrors}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PhyraPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Final verification', style: PhyraTextStyles.telemetryLabel),
                    const SizedBox(height: 8),
                    Text(
                      verificationLabel,
                      style: PhyraTextStyles.telemetryValue.copyWith(color: verificationColor),
                    ),
                  ],
                ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_saveError!, style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure)),
                ),
              const Spacer(),
              if (report.filePath != null) ...[
                OutlinedButton(
                  onPressed: _saveFile,
                  child: const Text('Save file'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PhyraTextStyles.telemetryLabel),
          Text(value, style: PhyraTextStyles.telemetryValueSmall),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
