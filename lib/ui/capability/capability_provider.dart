import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/channel/channel_capabilities.dart';
import '../../core/channel/channel_id.dart';
import '../../core/channel/channel_registry_provider.dart';
import '../../platform/channel_method_bridge.dart';

final channelCapabilitiesProvider =
    FutureProvider.family<ChannelCapabilities, ChannelId>((ref, id) async {
  return ref.read(channelRegistryProvider).forId(id).initialize();
});

final hardwareInventoryProvider = FutureProvider<Map<String, bool>>((ref) async {
  return ChannelMethodBridge().getCapabilities();
});

abstract class PermissionController {
  Future<void> request();
  Future<void> refresh();
}

class MicrophonePermissionController extends AsyncNotifier<PermissionStatus> implements PermissionController {
  @override
  Future<PermissionStatus> build() => Permission.microphone.status;

  @override
  Future<void> request() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.microphone.request());
  }

  @override
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.microphone.status);
  }
}

final microphonePermissionProvider =
    AsyncNotifierProvider<MicrophonePermissionController, PermissionStatus>(
  MicrophonePermissionController.new,
);

class CameraPermissionController extends AsyncNotifier<PermissionStatus> implements PermissionController {
  @override
  Future<PermissionStatus> build() => Permission.camera.status;

  @override
  Future<void> request() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.camera.request());
  }

  @override
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.camera.status);
  }
}

final cameraPermissionProvider =
    AsyncNotifierProvider<CameraPermissionController, PermissionStatus>(
  CameraPermissionController.new,
);
