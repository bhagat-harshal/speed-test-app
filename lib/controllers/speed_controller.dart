import 'dart:math';

import 'package:get/get.dart';

import '../data/result_repository.dart';
import '../models/speed_result.dart';
import '../services/speed_test_service.dart';
import '../data/app_database.dart';

enum SpeedTestStage { idle, ping, download, upload, done, error }

class SpeedController extends GetxController {
  final service = SpeedTestService();
  final repo = ResultRepository.instance;

  // Observables
  final stage = SpeedTestStage.idle.obs;
  final isRunning = false.obs;

  final pingMs = 0.0.obs;
  final downloadMbps = 0.0.obs;
  final uploadMbps = 0.0.obs;

  // Shown on the gauge while running (instantaneous)
  final gaugeMbps = 0.0.obs;
  final gaugeMax = 10.0
      .obs; // dynamic range; will expand based on observed speed to keep UI useful

  Future<void> initDb() async {
    await AppDatabase.instance.init();
  }

  void reset() {
    stage.value = SpeedTestStage.idle;
    isRunning.value = false;
    pingMs.value = 0;
    downloadMbps.value = 0;
    uploadMbps.value = 0;
    gaugeMbps.value = 0;
    gaugeMax.value = 100;
  }

  Future<SpeedResult?> runFullTest() async {
    if (isRunning.value) return null;
    await initDb();
    reset();
    isRunning.value = true;

    try {
      final connectionType = await service.getConnectionType();

      // Ping
      stage.value = SpeedTestStage.ping;
      final ping = await service.measurePingMs();
      pingMs.value = ping.isNaN ? 0 : ping;

      // Download
      stage.value = SpeedTestStage.download;
      gaugeMbps.value = 0;
      final dl = await service.measureDownloadMbps(onProgress: (v) {
        gaugeMbps.value = v;
        if (v > gaugeMax.value) gaugeMax.value = _roundUpScale(v);
      });
      downloadMbps.value = dl.isNaN ? 0 : dl;

      // Upload
      stage.value = SpeedTestStage.upload;
      gaugeMbps.value = 0;
      final ul = await service.measureUploadMbps(onProgress: (v) {
        gaugeMbps.value = v;
        if (v > gaugeMax.value) gaugeMax.value = _roundUpScale(v);
      });
      uploadMbps.value = ul.isNaN ? 0 : ul;

      // Done
      stage.value = SpeedTestStage.done;
      isRunning.value = false;

      final result = SpeedResult(
        timestamp: DateTime.now(),
        connectionType: connectionType,
        pingMs: pingMs.value,
        downloadMbps: downloadMbps.value,
        uploadMbps: uploadMbps.value,
      );

      final saved = await repo.add(result);
      return saved;
    } catch (e) {
      stage.value = SpeedTestStage.error;
      isRunning.value = false;
      return null;
    }
  }

  double _roundUpScale(double v) {
    // Round up to a pleasant scale for a dial, with more granular steps for small values
    if (v <= 0) return 5;
    
    // Handle very small values (less than 1 Mbps) with fine granularity
    if (v < 1) {
      if (v <= 0.1) return 0.2;
      if (v <= 0.2) return 0.5;
      if (v <= 0.5) return 1.0;
      return 2.0;
    }
    
    // Handle small values (1-10 Mbps) with medium granularity
    if (v < 10) {
      if (v <= 1) return 2.0;
      if (v <= 2) return 5.0;
      if (v <= 5) return 10.0;
      return 10.0;
    }
    
    // Debug: Print the value to see what's happening
    print('_roundUpScale called with v: $v');
    
    // For larger values, use the original pleasant scale logic
    final exp = (log(v) / log(10)).floor();
    final base = pow(10, exp);
    final candidates = [1, 2, 5, 10].map((m) => m * base).toList();
    
    // Debug: Print the calculated values
    print('exp: $exp, base: $base, candidates: $candidates');
    
    for (final c in candidates) {
      if (v <= c) {
        print('Returning: $c');
        return c.toDouble();
      }
    }
    
    final result = (10 * base).toDouble();
    print('Returning final: $result');
    return result;
  }

  @override
  void onClose() {
    service.dispose();
    super.onClose();
  }
}
