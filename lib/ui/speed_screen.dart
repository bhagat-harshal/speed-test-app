import 'dart:math' as math;
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

  int _calculateOptimalTickCount(double maxValue) {
    // Calculate optimal number of major ticks based on the max value
    // For better visual spacing and readability
    if (maxValue <= 20) {
      return 10; // More ticks for small ranges (0-20 Mbps)
    } else if (maxValue <= 100) {
      return 5;  // Fewer ticks for medium ranges (20-100 Mbps)
    } else {
      return 4;  // Even fewer ticks for large ranges (>100 Mbps)
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SpeedController>();

      return Obx(() {
        final isRunning = ctrl.isRunning.value;
        final stage = ctrl.stage.value;
        final gaugeMax = ctrl.gaugeMax.value <= 0 ? 10.0 : ctrl.gaugeMax.value;

        final gaugeVal = isRunning ? ctrl.gaugeMbps.value : 0.0;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SleekCircularSlider(
                        min: 0,
                        max: gaugeMax,
                        initialValue: gaugeVal.clamp(0.0, gaugeMax),
                        appearance: CircularSliderAppearance(
                          size: 260,
                          startAngle: 150,
                          angleRange: 240,
                          customWidths: CustomSliderWidths(
                            progressBarWidth: 16,
                            trackWidth: 12,
                          ),
                          customColors: CustomSliderColors(
                            trackColor:
                                Theme.of(
                                  context,
                                ).extension<NeonTheme>()?.ringTrack ??
                                Colors.grey.shade800,
                            progressBarColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            dotColor: Theme.of(context).colorScheme.primary,
                          ),
                          infoProperties: InfoProperties(
                            mainLabelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                            modifier: (double value) =>
                                '${value.toStringAsFixed(1)} Mbps',
                            bottomLabelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                            topLabelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                            
                          ),
                        ),
                        innerWidget: (double value) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${value.toStringAsFixed(1)} Mbps',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stageLabel(stage),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CustomPaint(
                          painter: _GaugeTicksPainter(
                            startAngleDeg: 150,
                            sweepAngleDeg: 240,
                            trackWidth: 24,
                            majorTickCount: _calculateOptimalTickCount(gaugeMax),
                            majorTickLength: 8,
                            minorTicksPerMajor: 4,
                            minorTickLength: 4,
                            color: Colors.white.withOpacity(0.8),
                            maxValue: gaugeMax,
                          ),
                        ),
                      ),
                    ],
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

class _GaugeTicksPainter extends CustomPainter {
  final double startAngleDeg;
  final double sweepAngleDeg;
  final double trackWidth;
  final int majorTickCount; // renders majorTickCount + 1 tick marks
  final double majorTickLength;
  final int minorTicksPerMajor; // number of minor ticks between major ticks
  final double minorTickLength;
  final Color color;
  final double maxValue;

  const _GaugeTicksPainter({
    required this.startAngleDeg,
    required this.sweepAngleDeg,
    required this.trackWidth,
    this.majorTickCount = 10,
    this.majorTickLength = 8,
    this.minorTicksPerMajor = 4, // 4 minor ticks between each major tick
    this.minorTickLength = 4,
    required this.color,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final outerR = radius - trackWidth / 2;
    final innerR = outerR - majorTickLength;
    
    // Position for tick marks (closer to center - below the arch)
    final tickOuterR = outerR - 5;  // Move ticks inward
    final tickInnerR = tickOuterR - majorTickLength;
    
    // Position for labels (further out - above the arch)
    final labelR = outerR + 25;  // Move labels further out

    // Create text style for tick labels
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw minor ticks first (so they appear behind major ticks)
    if (minorTicksPerMajor > 0) {
      final minorPaint = Paint()
        ..color = color.withOpacity(0.5) // Lighter color for minor ticks
        ..strokeWidth = 1.5 // Thinner line for minor ticks
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final minorTickOuterR = outerR - 5; // Same position as major ticks
      final minorTickInnerR = minorTickOuterR - minorTickLength;

      for (int i = 0; i < majorTickCount; i++) {
        for (int j = 1; j <= minorTicksPerMajor; j++) {
          final t = (i + j / (minorTicksPerMajor + 1)) / majorTickCount;
          final angle = (startAngleDeg + sweepAngleDeg * t) * (math.pi / 180.0);
          
          // Draw minor tick marks
          final minorTickP2 = Offset(
            center.dx + math.cos(angle) * minorTickOuterR,
            center.dy + math.sin(angle) * minorTickOuterR,
          );
          final minorTickP1 = Offset(
            center.dx + math.cos(angle) * minorTickInnerR,
            center.dy + math.sin(angle) * minorTickInnerR,
          );
          canvas.drawLine(minorTickP1, minorTickP2, minorPaint);
        }
      }
    }

    // Draw major ticks and labels
    for (int i = 0; i <= majorTickCount; i++) {
      final t = i / majorTickCount;
      final angle = (startAngleDeg + sweepAngleDeg * t) * (math.pi / 180.0);
      // Draw tick marks using the inward position
      final tickP2 = Offset(
        center.dx + math.cos(angle) * tickOuterR,
        center.dy + math.sin(angle) * tickOuterR,
      );
      final tickP1 = Offset(
        center.dx + math.cos(angle) * tickInnerR,
        center.dy + math.sin(angle) * tickInnerR,
      );
      canvas.drawLine(tickP1, tickP2, paint);

      // Draw tick labels (skip the first and last tick to avoid overlap)
      if (i > 0 && i < majorTickCount) {
        final value = (t * maxValue).roundToDouble(); // Calculate Mbps value
        
        // Format label based on the value scale for better readability
        String label;
        if (maxValue > 100) {
          // For large values (>100 Mbps), show integers only
          label = '${value.toInt()} Mbps';
        } else if (value == value.truncateToDouble()) {
          // For whole numbers, show as integer
          label = '${value.toInt()} Mbps';
        } else {
          // For fractional numbers, show one decimal place
          label = '${value.toStringAsFixed(1)} Mbps';
        }

        // Position the label using the outward position
        final labelX = center.dx + math.cos(angle) * labelR;
        final labelY = center.dy + math.sin(angle) * labelR;

        textPainter.text = TextSpan(text: label, style: textStyle);
        textPainter.layout();

        // Save the current canvas state
        canvas.save();
        
        // Translate to the label position
        canvas.translate(labelX, labelY);
        
        // Rotate the text to align with the arch
        // The angle needs to be adjusted by 90 degrees for proper text orientation
        final textAngle = angle + math.pi / 2;
        canvas.rotate(textAngle);
        
        // Center the text at the calculated position
        final textOffset = Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
        
        // Restore the canvas state
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeTicksPainter old) {
    return old.startAngleDeg != startAngleDeg ||
        old.sweepAngleDeg != sweepAngleDeg ||
        old.trackWidth != trackWidth ||
        old.majorTickCount != majorTickCount ||
        old.majorTickLength != majorTickLength ||
        old.minorTicksPerMajor != minorTicksPerMajor ||
        old.minorTickLength != minorTickLength ||
        old.color != color ||
        old.maxValue != maxValue;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({
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
        border: Border.all(
          color:
              Theme.of(context).extension<NeonTheme>()?.cardOutline ??
              color.withOpacity(0.25),
        ),
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
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
