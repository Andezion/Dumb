import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transfer_manager.dart';

final transferManagerProvider = NotifierProvider<TransferManager, TransferManagerState>(
  TransferManager.new,
);
