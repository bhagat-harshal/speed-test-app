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
  final gaugeMax = 100.0
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
    // Round up to a pleasant scale for a dial (20, 50, 100, 200, 500, etc.)
    if (v <= 0) return 10;
    final exp = (log(v) / log(10)).floor();
    final base = pow(10, exp);
    final candidates = [1, 2, 5, 10].map((m) => m * base).toList();
    for (final c in candidates) {
      if (v <= c) return c.toDouble();
    }
    return (10 * base).toDouble();
  }

  @override
  void onClose() {
    service.dispose();
    super.onClose();
  }
}
