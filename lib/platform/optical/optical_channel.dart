import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../core/channel/channel_capabilities.dart';
import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_metrics.dart';
import '../../core/channel/physical_channel.dart';
import '../../core/channel/received_symbol.dart';
import 'optical_config.dart';
import 'optical_frame_sampler.dart';
import 'optical_grid_frame.dart';

class OpticalChannel implements PhysicalChannel {
  OpticalChannel({this.config = const OpticalConfig()});

  @override
  final ChannelId id = ChannelId.optical;

  final OpticalConfig config;

  final StreamController<ChannelMetrics> _metrics = StreamController.broadcast();
  int _frameCounter = 0;
  bool _stopRequested = false;

  CameraController? _receiveController;
  bool _decoding = false;
  int? _lastAcceptedFrameIndex;
  int _framesLocked = 0;
  int _frameCrcErrors = 0;

  CameraController? get previewController => _receiveController;

  @override
  Stream<ChannelMetrics> get metrics => _metrics.stream;

  @override
  Future<ChannelCapabilities> initialize() async {
    debugPrint('[OpticalChannel] initialize()');
    try {
      final cameras = await availableCameras();
      debugPrint('[OpticalChannel] initialize() found ${cameras.length} camera(s)');
      if (cameras.isEmpty) {
        return const ChannelCapabilities(hardwareAvailable: false, unavailableReason: 'No camera available');
      }
      return const ChannelCapabilities(hardwareAvailable: true);
    } catch (e) {
      debugPrint('[OpticalChannel] initialize() FAILED: $e');
      return ChannelCapabilities(hardwareAvailable: false, unavailableReason: '$e');
    }
  }

  @override
  Future<Map<String, double>> calibrate() async {
    debugPrint('[OpticalChannel] calibrate()');
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('[OpticalChannel] calibrate() FAILED: no camera available');
      throw StateError('No camera available for calibration');
    }
    debugPrint('[OpticalChannel] calibrate() found ${cameras.length} camera(s)');
    return {'camerasFound': cameras.length.toDouble()};
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) async {
    _stopRequested = false;
    final frameDuration = Duration(milliseconds: this.config.frameDurationMs);
    debugPrint('[OpticalChannel] startTransmit() ${bits.length} bit(s), '
        'frameDuration=${frameDuration.inMilliseconds}ms');

    for (final chunk in _chunkBits(bits, OpticalGridFrame.payloadBitsPerFrame)) {
      if (_stopRequested) return;
      final payload = _bitsToPaddedBytes(chunk, OpticalGridFrame.payloadBytesPerFrame);
      final frameIndex = _frameCounter & 0xFF;
      _frameCounter++;
      final cells = OpticalGridFrame.encode(frameIndex: frameIndex, payload: payload);

      _metrics.add(OpticalMetrics(
        cells: cells,
        rows: OpticalGridFrame.rows,
        cols: OpticalGridFrame.cols,
        role: OpticalRole.transmitting,
        confidence: 1.0,
        frameIndex: frameIndex,
      ));

      await Future.delayed(frameDuration);
    }
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    debugPrint('[OpticalChannel] startReceive()');
    final controller = StreamController<ReceivedSymbol>();
    unawaited(_startReceiveLoop(controller));
    controller.onCancel = () async {
      await _stopReceiving();
    };
    return controller.stream;
  }

  Future<void> _startReceiveLoop(StreamController<ReceivedSymbol> sink) async {
    await _stopReceiving();
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('[OpticalChannel] opening camera ${back.name} (orientation=${back.sensorOrientation})');
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _receiveController = controller;
      await controller.initialize();
      _lastAcceptedFrameIndex = null;
      _framesLocked = 0;
      _frameCrcErrors = 0;

      debugPrint('[OpticalChannel] camera initialized, starting image stream');
      await controller.startImageStream((image) => _onCameraImage(image, back.sensorOrientation, sink));
    } catch (e) {
      debugPrint('[OpticalChannel] ERROR: receive loop failed to start: $e');
      sink.addError(e);
    }
  }

  void _onCameraImage(CameraImage image, int sensorOrientation, StreamController<ReceivedSymbol> sink) {
    if (_decoding || sink.isClosed) return;
    _decoding = true;
    try {
      final yPlane = image.planes.first;
      final sample = OpticalFrameSampler.sample(
        yPlane: yPlane.bytes,
        bytesPerRow: yPlane.bytesPerRow,
        bufferWidth: image.width,
        bufferHeight: image.height,
        sensorOrientationDegrees: sensorOrientation,
      );

      if (sample.contrast < _kMinContrastForSearch) {
        _metrics.add(OpticalMetrics(
          cells: sample.cells,
          rows: OpticalGridFrame.rows,
          cols: OpticalGridFrame.cols,
          role: OpticalRole.idle,
          confidence: sample.contrast,
          framesLocked: _framesLocked,
          frameCrcErrors: _frameCrcErrors,
        ));
        return;
      }

      final decoded = OpticalGridFrame.decode(sample.cells);
      if (!decoded.syncOk) {
        _metrics.add(OpticalMetrics(
          cells: sample.cells,
          rows: OpticalGridFrame.rows,
          cols: OpticalGridFrame.cols,
          role: OpticalRole.searching,
          confidence: sample.contrast,
          framesLocked: _framesLocked,
          frameCrcErrors: _frameCrcErrors,
        ));
        return;
      }

      if (!decoded.crcOk) {
        _frameCrcErrors++;
        debugPrint('[OpticalChannel] frame CRC error (total=$_frameCrcErrors)');
      } else if (decoded.frameIndex != _lastAcceptedFrameIndex) {
        _lastAcceptedFrameIndex = decoded.frameIndex;
        _framesLocked++;
        debugPrint('[OpticalChannel] frame ${decoded.frameIndex} accepted (locked=$_framesLocked)');
        final bits = _bytesToBits(decoded.payload);
        final timestampUs = DateTime.now().microsecondsSinceEpoch;
        for (final bit in bits) {
          sink.add(ReceivedSymbol(bit: bit, confidence: sample.contrast, timestampUs: timestampUs));
        }
      }

      _metrics.add(OpticalMetrics(
        cells: sample.cells,
        rows: OpticalGridFrame.rows,
        cols: OpticalGridFrame.cols,
        role: OpticalRole.locked,
        confidence: sample.contrast,
        frameIndex: decoded.frameIndex,
        framesLocked: _framesLocked,
        frameCrcErrors: _frameCrcErrors,
      ));
    } finally {
      _decoding = false;
    }
  }

  Future<void> _stopReceiving() async {
    final controller = _receiveController;
    _receiveController = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Already stopped/disposed - nothing to clean up
    }
    await controller.dispose();
  }

  @override
  Future<void> stop() async {
    debugPrint('[OpticalChannel] stop()');
    _stopRequested = true;
    await _stopReceiving();
  }

  static const double _kMinContrastForSearch = 0.12;

  static Iterable<List<int>> _chunkBits(List<int> bits, int chunkSize) sync* {
    for (var i = 0; i < bits.length; i += chunkSize) {
      yield bits.sublist(i, (i + chunkSize).clamp(0, bits.length));
    }
  }

  static Uint8List _bitsToPaddedBytes(List<int> bits, int byteCount) {
    final padded = List<int>.filled(byteCount * 8, 0);
    for (var i = 0; i < bits.length; i++) {
      padded[i] = bits[i];
    }
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      var value = 0;
      for (var b = 0; b < 8; b++) {
        value = (value << 1) | (padded[i * 8 + b] & 1);
      }
      bytes[i] = value;
    }
    return bytes;
  }

  static List<int> _bytesToBits(Uint8List bytes) {
    final bits = List<int>.filled(bytes.length * 8, 0);
    var i = 0;
    for (final byte in bytes) {
      for (var b = 7; b >= 0; b--) {
        bits[i++] = (byte >> b) & 1;
      }
    }
    return bits;
  }
}
