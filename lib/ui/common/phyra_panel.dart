import 'package:flutter/material.dart';

import '../../theme/phyra_colors.dart';

class PhyraPanel extends StatelessWidget {
  const PhyraPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PhyraColors.nearBlack,
        border: Border.all(color: PhyraColors.darkGray),
      ),
      child: child,
    );
  }
}
