import 'package:flutter/material.dart';

import '../../theme/phyra_colors.dart';
import '../../theme/phyra_text_styles.dart';
import '../about/philosophy_screen.dart';
import '../capability/hardware_capability_screen.dart';
import '../channel_select/channel_select_screen.dart';
import '../common/transfer_intent.dart';
import '../debug/frequency_config_screen.dart';
import '../debug/mode_a_demo_screen.dart';
import '../lab/rolling_shutter_experiment_screen.dart';
import '../transmit/file_pick_screen.dart';
import 'widgets/signal_propagation_visualization.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: Text('PHYRA', style: PhyraTextStyles.title)),
              const SizedBox(height: 8),
              const Center(
                child: Text('Physical communication lab', style: PhyraTextStyles.subtitle),
              ),
              const SizedBox(height: 24),
              const Text(
                'Two devices.\nNo conventional network.',
                textAlign: TextAlign.center,
                style: PhyraTextStyles.body,
              ),
              const SizedBox(height: 32),
              const Divider(),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _push(context, const FilePickScreen()),
                child: const Text('Transmit'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _push(context, const ChannelSelectScreen(intent: TransferIntent.receive)),
                child: const Text('Receive'),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 16),
              const SignalPropagationVisualization(),
              const SizedBox(height: 16),
              const Center(
                child: Text('5 Physical channels - 0 network needed', style: PhyraTextStyles.telemetryLabel),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _footerLink(context, 'About', () => _push(context, const PhilosophyScreen())),
                  _footerDot(),
                  _footerLink(context, 'Hardware', () => _push(context, const HardwareCapabilityScreen())),
                  _footerDot(),
                  _footerLink(context, 'Lab', () => _showLabMenu(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: PhyraTextStyles.telemetryLabel.copyWith(color: PhyraColors.lightGray)),
    );
  }

  Widget _footerDot() => const Text('-', style: PhyraTextStyles.telemetryLabel);

  void _showLabMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PhyraColors.nearBlack,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Mode A - sigmal demo', style: PhyraTextStyles.buttonLabel),
                onTap: () {
                  Navigator.of(context).pop();
                  _push(context, const ModeADemoScreen());
                },
              ),
              ListTile(
                title: const Text('Acoustic debag config', style: PhyraTextStyles.buttonLabel),
                onTap: () {
                  Navigator.of(context).pop();
                  _push(context, const FrequencyConfigScreen());
                },
              ),
              ListTile(
                title: const Text('Rolling shutter experiment', style: PhyraTextStyles.buttonLabel),
                onTap: () {
                  Navigator.of(context).pop();
                  _push(context, const RollingShutterExperimentScreen());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
