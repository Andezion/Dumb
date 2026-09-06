import 'package:flutter/material.dart';

import 'theme/phyra_theme.dart';
import 'ui/home/home_screen.dart';

class PhyraApp extends StatelessWidget {
  const PhyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHYRA',
      debugShowCheckedModeBanner: false,
      theme: buildPhyraTheme(),
      home: const HomeScreen(),
    );
  }
}
