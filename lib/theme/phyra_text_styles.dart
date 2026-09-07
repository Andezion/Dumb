import 'package:flutter/material.dart';

import 'phyra_colors.dart';

abstract final class PhyraTextStyles {
  static const String _monoFamily = 'monospace';

  static const TextStyle title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: 6,
    color: PhyraColors.white,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 2,
    color: PhyraColors.lightGray,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    color: PhyraColors.mediumGray,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: PhyraColors.lightGray,
    height: 1.5,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 3,
    color: PhyraColors.white,
  );

  static const TextStyle telemetryValue = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: PhyraColors.white,
  );

  static const TextStyle telemetryValueSmall = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: PhyraColors.white,
  );

  static const TextStyle telemetryLabel = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    color: PhyraColors.mediumGray,
  );
}
