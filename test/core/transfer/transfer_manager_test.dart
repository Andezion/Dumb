import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/channel/channel_id.dart';
import 'package:phyra/core/channel/channel_registry.dart';
import 'package:phyra/core/channel/channel_registry_provider.dart';
import 'package:phyra/core/channel/not_implemented_channel.dart';
import 'package:phyra/core/channel/simulated_channel.dart';
import 'package:phyra/core/transfer/transfer_manager_provider.dart';
import 'package:phyra/core/transfer/transfer_state.dart';

ChannelRegistry _registryAround(SimulatedChannel sharedAcoustic) {
  return ChannelRegistry({
    ChannelId.acoustic: sharedAcoustic,
    ChannelId.mechanical: NotImplementedChannel(ChannelId.mechanical),
    ChannelId.magnetic: NotImplementedChannel(ChannelId.magnetic),
    ChannelId.optical: NotImplementedChannel(ChannelId.optical),
    ChannelId.ambientLight: NotImplementedChannel(ChannelId.ambientLight),
  });
}

void main() {
  test('transmits a small file and the receiver reconstructs + verifies it', () async {
    final sharedChannel = SimulatedChannel(
      id: ChannelId.acoustic,
      symbolDuration: const Duration(milliseconds: 1),
      calibrationLatency: Duration.zero,
    );

    final senderContainer = ProviderContainer(
      overrides: [channelRegistryProvider.overrideWithValue(_registryAround(sharedChannel))],
    );
    final receiverContainer = ProviderContainer(
      overrides: [channelRegistryProvider.overrideWithValue(_registryAround(sharedChannel))],
    );
    addTearDown(senderContainer.dispose);
    addTearDown(receiverContainer.dispose);

    final dir = await Directory.systemTemp.createTemp('phyra_test');
    addTearDown(() => dir.delete(recursive: true));

    final sourceFile = File('${dir.path}/hello.txt');
    const content = 'HELLO PHYRA AUDIO TEST FILE 1234567890!!';
    await sourceFile.writeAsBytes(utf8.encode(content));

    final receiveFuture = receiverContainer.read(transferManagerProvider.notifier).startReceiveFile(
          channelId: ChannelId.acoustic,
          saveDirectory: dir,
        );

    while (receiverContainer.read(transferManagerProvider).phase is! TransferReceiving) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    await senderContainer.read(transferManagerProvider.notifier).startTransmit(
          channelId: ChannelId.acoustic,
          file: sourceFile,
        );
    await receiveFuture;

    final receiverState = receiverContainer.read(transferManagerProvider);
    expect(receiverState.phase, isA<TransferComplete>());
    expect(receiverState.report, isNotNull);
    expect(receiverState.report!.verified, isTrue);

    final receivedFile = File('${dir.path}/${receiverState.report!.fileName}');
    expect(await receivedFile.readAsString(), content);

    final senderState = senderContainer.read(transferManagerProvider);
    expect(senderState.phase, isA<TransferComplete>());
  }, timeout: const Timeout(Duration(seconds: 30)));
}
