import 'package:flutter/material.dart';

import '../../theme/phyra_text_styles.dart';

class PhilosophyScreen extends StatelessWidget {
  const PhilosophyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONCEPT')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: const [
              Text('PHYRA does not create new information.', style: PhyraTextStyles.body),
              SizedBox(height: 16),
              Text('Every transfer is ultimately digital.', style: PhyraTextStyles.body),
              SizedBox(height: 16),
              Text('The experiment is about the physical medium.', style: PhyraTextStyles.body),
              SizedBox(height: 24),
              Text('Sound.\nMotion.\nMagnetic fields.\nLight.', style: PhyraTextStyles.telemetryValueSmall),
              SizedBox(height: 24),
              Text(
                'The same bytes can travel through different physical phenomena.',
                style: PhyraTextStyles.body,
              ),
              SizedBox(height: 32),
              Text(
                'A network protocol is not the same thing as a physical communication channel.',
                style: PhyraTextStyles.sectionLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
