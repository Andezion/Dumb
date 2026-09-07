import 'package:flutter/material.dart';

import 'phyra_colors.dart';
import 'phyra_text_styles.dart';

ThemeData buildPhyraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PhyraColors.black,
    colorScheme: const ColorScheme.dark(
      surface: PhyraColors.nearBlack,
      primary: PhyraColors.white,
      secondary: PhyraColors.lightGray,
      error: PhyraColors.failure,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PhyraColors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: PhyraTextStyles.sectionLabel,
      iconTheme: IconThemeData(color: PhyraColors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: PhyraTextStyles.title,
      titleMedium: PhyraTextStyles.subtitle,
      labelLarge: PhyraTextStyles.buttonLabel,
      bodyMedium: PhyraTextStyles.body,
    ),
    dividerTheme: const DividerThemeData(
      color: PhyraColors.darkGray,
      thickness: 1,
      space: 1,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PhyraColors.white,
        side: const BorderSide(color: PhyraColors.mediumGray, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        textStyle: PhyraTextStyles.buttonLabel,
      ),
    ),
    cardTheme: CardThemeData(
      color: PhyraColors.nearBlack,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: PhyraColors.darkGray, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    fontFamily: null,
  );
}
