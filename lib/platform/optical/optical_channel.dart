import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../core/channel/channel_capabilities.dart';
import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_metrics.dart';
import '../../core/channel/physical_channel.dart';
import '../../core/channel/preamble_sync.dart';
import '../../core/channel/received_symbol.dart';
import '../../core/channel/symbol_lock_fsm.dart';
import 'optical_config.dart';
import 'optical_frame_sampler.dart';
import 'optical_grid_frame.dart';
import 'optical_qr_frame.dart';
import 'yuv420_to_nv21.dart';

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

  CameraController? _flashTransmitController;
  Timer? _flashSymbolTimer;
  double _flashLatestBrightness = 0;
  double _flashRestBrightness = 0;
  double _flashNoiseStdDev = 0;

  BarcodeScanner? _barcodeScanner;
  bool _qrProcessing = false;

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
    if (config.mode == OpticalMode.flash) {
      return _calibrateFlash();
    }
    debugPrint('[OpticalChannel] calibrate()');
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('[OpticalChannel] calibrate() FAILED: no camera available');
      throw StateError('No camera available for calibration');
    }
    debugPrint('[OpticalChannel] calibrate() found ${cameras.length} camera(s)');
    return {'camerasFound': cameras.length.toDouble()};
  }

  Future<Map<String, double>> _calibrateFlash() async {
    debugPrint('[OpticalChannel] calibrateFlash()');
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('[OpticalChannel] calibrateFlash() FAILED: no camera available');
      throw StateError('No camera available for calibration');
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      back,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    final samples = <double>[];
    try {
      await controller.initialize();
      await controller.startImageStream((image) {
        if (samples.length < _kFlashCalibrationSamples) {
          samples.add(OpticalFrameSampler.averageLuma(image.planes.first.bytes));
        }
      });
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (samples.length < _kFlashCalibrationSamples && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } finally {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }

    if (samples.isEmpty) {
      throw StateError('Could not read camera brightness for calibration');
    }

    final mean = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / samples.length;
    final stdDev = math.sqrt(variance);
    _flashRestBrightness = mean;
    _flashNoiseStdDev = stdDev;
    debugPrint('[OpticalChannel] calibrateFlash() restBrightness=$mean noiseStdDev=$stdDev');

    return {'restBrightness': mean, 'noiseStdDevBrightness': stdDev};
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) async {
    if (this.config.mode == OpticalMode.flash) {
      return _startFlashTransmit(bits);
    }
    if (this.config.mode == OpticalMode.qrFrames) {
      return _startQrTransmit(bits);
    }
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

  Future<void> _startFlashTransmit(List<int> bits) async {
    _stopRequested = false;
    debugPrint('[OpticalChannel] startFlashTransmit() ${bits.length} bit(s)');
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera available for flash transmission');
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(back, ResolutionPreset.low, enableAudio: false);
    _flashTransmitController = controller;
    final symbolDuration = Duration(milliseconds: config.flashSymbolDurationMs);
    try {
      await controller.initialize();
      final fullBits = [...PreambleSync.header(), ...bits];
      for (final bit in fullBits) {
        if (_stopRequested) break;
        await controller.setFlashMode(bit == 1 ? FlashMode.torch : FlashMode.off);
        _metrics.add(OpticalFlashMetrics(
          brightness: bit.toDouble(),
          thresholdBrightness: 0.5,
          role: OpticalRole.transmitting,
          confidence: 1.0,
          detectedSymbol: bit,
        ));
        await Future.delayed(symbolDuration);
      }
    } finally {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Torch may already be unavailable if the controller failed mid-setup
      }
      await controller.dispose();
      _flashTransmitController = null;
    }
  }

  Future<void> _startQrTransmit(List<int> bits) async {
    _stopRequested = false;
    final frameDuration = Duration(milliseconds: config.qrFrameDurationMs);
    debugPrint('[OpticalChannel] startQrTransmit() ${bits.length} bit(s), '
        'frameDuration=${frameDuration.inMilliseconds}ms');

    for (final chunk in _chunkBits(bits, OpticalQrFrame.payloadBitsPerFrame)) {
      if (_stopRequested) return;
      final payload = _bitsToPaddedBytes(chunk, OpticalQrFrame.payloadBytesPerFrame);
      final frameIndex = _frameCounter & 0xFF;
      _frameCounter++;
      final frameBytes = OpticalQrFrame.encode(frameIndex: frameIndex, payload: payload);

      _metrics.add(OpticalQrMetrics(
        role: OpticalRole.transmitting,
        confidence: 1.0,
        frameIndex: frameIndex,
        qrFrameBytes: frameBytes,
      ));

      await Future.delayed(frameDuration);
    }
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    debugPrint('[OpticalChannel] startReceive() mode=${this.config.mode}');
    final controller = StreamController<ReceivedSymbol>();
    switch (this.config.mode) {
      case OpticalMode.flash:
        unawaited(_startFlashReceiveLoop(controller));
      case OpticalMode.qrFrames:
        unawaited(_startQrReceiveLoop(controller));
      case OpticalMode.screenGrid:
        unawaited(_startReceiveLoop(controller));
    }
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

  Future<void> _startFlashReceiveLoop(StreamController<ReceivedSymbol> sink) async {
    await _stopReceiving();
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('[OpticalChannel] opening camera ${back.name} for flash receive');
      final controller = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _receiveController = controller;
      await controller.initialize();

      final threshold =
          _flashRestBrightness + math.max(_flashNoiseStdDev * _kFlashNoiseMarginFactor, _kFlashMinDeltaBrightness);
      final fsm = SymbolLockFsm(threshold);

      await controller.startImageStream((image) {
        _flashLatestBrightness = OpticalFrameSampler.averageLuma(image.planes.first.bytes);
      });

      _flashSymbolTimer = Timer.periodic(Duration(milliseconds: config.flashSymbolDurationMs), (_) {
        if (sink.isClosed) return;
        final brightness = _flashLatestBrightness;
        final bit = brightness > threshold ? 1 : 0;
        final confidence = ((brightness - threshold).abs() / math.max(threshold, 1.0)).clamp(0.0, 1.0);
        final locked = fsm.onBlock(bit, brightness);

        _metrics.add(OpticalFlashMetrics(
          brightness: brightness,
          thresholdBrightness: threshold,
          role: _roleForLockState(fsm.state),
          confidence: confidence,
          detectedSymbol: bit,
        ));

        if (locked) {
          sink.add(ReceivedSymbol(bit: bit, confidence: confidence, timestampUs: DateTime.now().microsecondsSinceEpoch));
        }
      });
    } catch (e) {
      debugPrint('[OpticalChannel] ERROR: flash receive loop failed to start: $e');
      sink.addError(e);
    }
  }

  static OpticalRole _roleForLockState(SymbolLockState state) => switch (state) {
        SymbolLockState.idle => OpticalRole.idle,
        SymbolLockState.searchingSync => OpticalRole.searching,
        SymbolLockState.streaming => OpticalRole.locked,
      };

  Future<void> _startQrReceiveLoop(StreamController<ReceivedSymbol> sink) async {
    await _stopReceiving();
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('[OpticalChannel] opening camera ${back.name} for QR receive');
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
      _barcodeScanner ??= BarcodeScanner(formats: [BarcodeFormat.qrCode]);

      debugPrint('[OpticalChannel] camera initialized, starting QR image stream');
      await controller.startImageStream((image) => _onQrCameraImage(image, back.sensorOrientation, sink));
    } catch (e) {
      debugPrint('[OpticalChannel] ERROR: QR receive loop failed to start: $e');
      sink.addError(e);
    }
  }

  void _onQrCameraImage(CameraImage image, int sensorOrientation, StreamController<ReceivedSymbol> sink) {
    if (_qrProcessing || sink.isClosed) return;
    _qrProcessing = true;
    unawaited(_processQrImage(image, sensorOrientation, sink).whenComplete(() => _qrProcessing = false));
  }

  Future<void> _processQrImage(CameraImage image, int sensorOrientation, StreamController<ReceivedSymbol> sink) async {
    final scanner = _barcodeScanner;
    if (scanner == null || sink.isClosed) return;
    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final nv21 = Yuv420Converter.toNv21(
        yBytes: yPlane.bytes,
        yBytesPerRow: yPlane.bytesPerRow,
        uBytes: uPlane.bytes,
        uBytesPerRow: uPlane.bytesPerRow,
        uPixelStride: uPlane.bytesPerPixel ?? 1,
        vBytes: vPlane.bytes,
        vBytesPerRow: vPlane.bytesPerRow,
        vPixelStride: vPlane.bytesPerPixel ?? 1,
        width: image.width,
        height: image.height,
      );

      final inputImage = InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );

      final barcodes = await scanner.processImage(inputImage);
      Uint8List? rawBytes;
      for (final barcode in barcodes) {
        if (barcode.rawBytes != null) {
          rawBytes = barcode.rawBytes;
          break;
        }
      }

      if (rawBytes == null) {
        _metrics.add(OpticalQrMetrics(
          role: OpticalRole.searching,
          confidence: 0.0,
          framesLocked: _framesLocked,
          frameCrcErrors: _frameCrcErrors,
        ));
        return;
      }

      final decoded = OpticalQrFrame.decode(rawBytes);
      if (decoded == null) {
        _metrics.add(OpticalQrMetrics(
          role: OpticalRole.searching,
          confidence: 0.5,
          framesLocked: _framesLocked,
          frameCrcErrors: _frameCrcErrors,
        ));
        return;
      }

      if (!decoded.crcOk) {
        _frameCrcErrors++;
        debugPrint('[OpticalChannel] QR frame CRC error (total=$_frameCrcErrors)');
      } else if (decoded.frameIndex != _lastAcceptedFrameIndex) {
        _lastAcceptedFrameIndex = decoded.frameIndex;
        _framesLocked++;
        debugPrint('[OpticalChannel] QR frame ${decoded.frameIndex} accepted (locked=$_framesLocked)');
        final bits = _bytesToBits(decoded.payload);
        final timestampUs = DateTime.now().microsecondsSinceEpoch;
        for (final bit in bits) {
          sink.add(ReceivedSymbol(bit: bit, confidence: 1.0, timestampUs: timestampUs));
        }
      }

      _metrics.add(OpticalQrMetrics(
        role: OpticalRole.locked,
        confidence: 1.0,
        frameIndex: decoded.frameIndex,
        framesLocked: _framesLocked,
        frameCrcErrors: _frameCrcErrors,
      ));
    } catch (e) {
      debugPrint('[OpticalChannel] QR decode error: $e');
    }
  }

  Future<void> _stopReceiving() async {
    _flashSymbolTimer?.cancel();
    _flashSymbolTimer = null;
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
    final txController = _flashTransmitController;
    if (txController != null) {
      try {
        await txController.setFlashMode(FlashMode.off);
      } catch (_) {
        // Already stopped/disposed - nothing to clean up
      }
      await txController.dispose();
      _flashTransmitController = null;
    }
    final scanner = _barcodeScanner;
    if (scanner != null) {
      _barcodeScanner = null;
      await scanner.close();
    }
  }

  static const double _kMinContrastForSearch = 0.12;
  static const int _kFlashCalibrationSamples = 15;
  static const double _kFlashNoiseMarginFactor = 4.0;
  static const double _kFlashMinDeltaBrightness = 10.0;

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
