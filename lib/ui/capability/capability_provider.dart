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

class MicrophonePermissionController extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() => Permission.microphone.status;

  Future<void> request() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.microphone.request());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await Permission.microphone.status);
  }
}

final microphonePermissionProvider =
    AsyncNotifierProvider<MicrophonePermissionController, PermissionStatus>(
  MicrophonePermissionController.new,
);
