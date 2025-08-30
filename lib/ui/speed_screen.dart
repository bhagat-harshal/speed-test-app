import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../controllers/speed_controller.dart';
import '../theme/app_theme.dart';

class SpeedScreen extends StatelessWidget {
  const SpeedScreen({super.key});

  String _stageLabel(SpeedTestStage stage) {
    switch (stage) {
      case SpeedTestStage.idle:
        return 'Ready';
      case SpeedTestStage.ping:
        return 'Pinging';
      case SpeedTestStage.download:
        return 'Downloading';
      case SpeedTestStage.upload:
        return 'Uploading';
      case SpeedTestStage.done:
        return 'Completed';
      case SpeedTestStage.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SpeedController>();

    return Obx(() {
      final isRunning = ctrl.isRunning.value;
      final stage = ctrl.stage.value;
      final gaugeMax = (ctrl.gaugeMax.value <= 0 ? 10.0 : ctrl.gaugeMax.value);
      final gaugeVal = isRunning ? ctrl.gaugeMbps.value : 0.0;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SleekCircularSlider(
                    min: 0,
                    max: gaugeMax,
                    initialValue: gaugeVal.clamp(0.0, gaugeMax),
                    appearance: CircularSliderAppearance(
                      size: 260,
                      customWidths: CustomSliderWidths(
                        progressBarWidth: 16,
                        trackWidth: 12,
                      ),
                      customColors: CustomSliderColors(
                        trackColor: Theme.of(context).extension<NeonTheme>()?.ringTrack ?? Colors.grey.shade800,
                        progressBarColor: Theme.of(context).colorScheme.primary,
                        dotColor: Theme.of(context).colorScheme.primary,
                      ),
                      infoProperties: InfoProperties(
                        mainLabelStyle: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        modifier: (double value) => '${value.toStringAsFixed(1)} Mbps',
                      ),
                    ),
                    innerWidget: (double _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Text(
                            _stageLabel(stage),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    title: 'Ping',
                    value: '${ctrl.pingMs.value.toStringAsFixed(0)} ms',
                    icon: Icons.podcasts,
                  ),
                  _StatCard(
                    title: 'Down',
                    value: '${ctrl.downloadMbps.value.toStringAsFixed(1)} Mbps',
                    icon: Icons.download,
                  ),
                  _StatCard(
                    title: 'Up',
                    value: '${ctrl.uploadMbps.value.toStringAsFixed(1)} Mbps',
                    icon: Icons.upload,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isRunning
                      ? null
                      : () async {
                          await ctrl.runFullTest();
                        },
                  icon: isRunning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.speed),
                  label: Text(isRunning ? 'Testing...' : 'GO'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<NeonTheme>()?.cardOutline ?? color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
