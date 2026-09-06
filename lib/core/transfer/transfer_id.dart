import 'dart:math';

final Random _random = Random();

int generateTransferId() => _random.nextInt(0xFFFFFFFF);
