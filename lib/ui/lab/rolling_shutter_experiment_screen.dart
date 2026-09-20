import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../platform/optical/row_brightness_profile.dart';
import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../common/phyra_panel.dart';
import '../transfer_panel/widgets/waveform_graph.dart';

enum _RollingShutterRole { blink, watch }

class RollingShutterExperimentScreen extends StatefulWidget {
  const RollingShutterExperimentScreen({super.key});

  @override
  State<RollingShutterExperimentScreen> createState() => _RollingShutterExperimentScreenState();
}

class _RollingShutterExperimentScreenState extends State<RollingShutterExperimentScreen> {
  _RollingShutterRole _role = _RollingShutterRole.blink;

  CameraController? _blinkController;
  bool _blinking = false;
  double _targetIntervalMs = 10;
  double _achievedHz = 0;
  int _toggleCount = 0;
  String? _blinkError;

  CameraController? _watchController;
  bool _watching = false;
  bool _analyzing = false;
  List<double> _rowProfile = const [];
  int _meanCrossings = 0;
  String? _watchError;

  @override
  void dispose() {
    _blinkController?.dispose();
    _watchController?.dispose();
    super.dispose();
  }

  Future<void> _startBlink() async {
    setState(() {
      _blinkError = null;
      _toggleCount = 0;
      _achievedHz = 0;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera available');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.low, enableAudio: false);
      _blinkController = controller;
      await controller.initialize();
      setState(() => _blinking = true);

      final stopwatch = Stopwatch()..start();
      var lastReportMs = 0;
      var torchOn = false;
      while (_blinking) {
        torchOn = !torchOn;
        await controller.setFlashMode(torchOn ? FlashMode.torch : FlashMode.off);
        _toggleCount++;
        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastReportMs >= 200) {
          lastReportMs = elapsedMs;
          if (mounted) setState(() => _achievedHz = _toggleCount / (elapsedMs / 1000.0));
        }
        final targetMs = _targetIntervalMs.round();
        if (targetMs > 0) await Future.delayed(Duration(milliseconds: targetMs));
      }
    } catch (e) {
      if (mounted) setState(() => _blinkError = '$e');
    } finally {
      _blinking = false;
      final controller = _blinkController;
      _blinkController = null;
      if (controller != null) {
        try {
          await controller.setFlashMode(FlashMode.off);
        } catch (_) {
          // Already stopped/disposed - nothing to clean up
        }
        await controller.dispose();
      }
      if (mounted) setState(() {});
    }
  }

  void _stopBlink() => setState(() => _blinking = false);

  Future<void> _startWatch() async {
    setState(() {
      _watchError = null;
      _rowProfile = const [];
      _meanCrossings = 0;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera available');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _watchController = controller;
      await controller.initialize();
      setState(() => _watching = true);
      await controller.startImageStream(_onCameraImage);
    } catch (e) {
      if (mounted) setState(() => _watchError = '$e');
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_analyzing) return;
    _analyzing = true;
    try {
      final yPlane = image.planes.first;
      final profile = RowBrightnessProfile.compute(
        yPlane: yPlane.bytes,
        bytesPerRow: yPlane.bytesPerRow,
        bufferWidth: image.width,
        bufferHeight: image.height,
      );
      if (mounted) {
        setState(() {
          _rowProfile = profile;
          _meanCrossings = RowBrightnessProfile.countMeanCrossings(profile);
        });
      }
    } finally {
      _analyzing = false;
    }
  }

  Future<void> _stopWatch() async {
    final controller = _watchController;
    _watchController = null;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) await controller.stopImageStream();
      } catch (_) {
        // Already stopped/disposed - nothing to clean up
      }
      await controller.dispose();
    }
    if (mounted) setState(() => _watching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rolling shutter experiment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                'Fast temporal light changes can produce spatial stripes on a rolling-shutter '
                'sensor. This is a diagnostic tool, not a reliable transfer method.',
                style: PhyraTextStyles.body,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      label: 'Blink',
                      selected: _role == _RollingShutterRole.blink,
                      onTap: () => setState(() => _role = _RollingShutterRole.blink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoleButton(
                      label: 'Watch',
                      selected: _role == _RollingShutterRole.watch,
                      onTap: () => setState(() => _role = _RollingShutterRole.watch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_role == _RollingShutterRole.blink) _buildBlinkPanel() else _buildWatchPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlinkPanel() {
    return PhyraPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target interval', style: PhyraTextStyles.telemetryLabel),
              Text('${_targetIntervalMs.round()} ms', style: PhyraTextStyles.telemetryValueSmall),
            ],
          ),
          Slider(
            value: _targetIntervalMs,
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: _blinking ? null : (v) => setState(() => _targetIntervalMs = v),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achieved rate', style: PhyraTextStyles.telemetryLabel),
              Text('${_achievedHz.toStringAsFixed(1)} Hz', style: PhyraTextStyles.telemetryValueSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text('Toggles sent: $_toggleCount', style: PhyraTextStyles.telemetryLabel),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _blinking ? _stopBlink : _startBlink,
              child: Text(_blinking ? 'Stop' : 'Start blinking'),
            ),
          ),
          if (_blinkError != null) ...[
            const SizedBox(height: 12),
            Text(_blinkError!, style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure)),
          ],
        ],
      ),
    );
  }

  Widget _buildWatchPanel() {
    final controller = _watchController;
    final initialized = controller != null && controller.value.isInitialized;
    return PhyraPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (initialized)
            SizedBox(
              height: 140,
              child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: CameraPreview(controller)),
            )
          else
            const SizedBox(
              height: 140,
              child: Center(child: Text('Camera not started', style: PhyraTextStyles.telemetryLabel)),
            ),
          const SizedBox(height: 12),
          WaveformGraph(
            label: 'Row brightness (sensor readout order, top to bottom)',
            samples: _rowProfile,
            maxValue: 255,
          ),
          const SizedBox(height: 8),
          Text('Mean crossings: $_meanCrossings', style: PhyraTextStyles.telemetryLabel),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _watching ? _stopWatch : _startWatch,
              child: Text(_watching ? 'Stop' : 'Start watching'),
            ),
          ),
          if (_watchError != null) ...[
            const SizedBox(height: 12),
            Text(_watchError!, style: PhyraTextStyles.body.copyWith(color: PhyraColors.failure)),
          ],
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? PhyraColors.white : Colors.transparent,
        foregroundColor: selected ? PhyraColors.black : PhyraColors.white,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
