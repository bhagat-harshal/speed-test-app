import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

typedef ProgressCallback = void Function(double mbps);

class SpeedTestService {
  final http.Client _client;
  SpeedTestService({http.Client? client}) : _client = client ?? http.Client();

  // Returns Wi‑Fi, Mobile, Ethernet or None
  Future<String> getConnectionType() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.wifi)) return 'Wi‑Fi';
    if (result.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (result.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (result.contains(ConnectivityResult.vpn)) return 'VPN';
    return 'None';
  }

  // Measure ping by averaging several HEAD requests.
  Future<double> measurePingMs({int samples = 5, Duration timeout = const Duration(seconds: 5)}) async {
    const url = 'https://www.google.com/generate_204';
    final times = <double>[];
    for (var i = 0; i < samples; i++) {
      final sw = Stopwatch()..start();
      try {
        final res = await _client.head(Uri.parse(url)).timeout(timeout);
        if (res.statusCode >= 200 && res.statusCode < 400) {
          sw.stop();
          times.add(sw.elapsedMicroseconds / 1000.0);
        }
      } catch (_) {
        sw.stop();
        // Ignore this sample
      }
      // Small spacing between pings
      await Future.delayed(const Duration(milliseconds: 120));
    }
    if (times.isEmpty) return double.nan;
    // drop the worst outlier if enough samples
    times.sort();
    if (times.length >= 4) {
      times.removeLast();
    }
    final avg = times.reduce((a, b) => a + b) / times.length;
    return avg;
  }

  // Measure download speed by streaming X bytes from Cloudflare.
  // Returns average Mbps. Provides live progress via onProgress (instantaneous Mbps).
  Future<double> measureDownloadMbps({
    int bytes = 20 * 1000 * 1000, // 20 MB
    Duration timeout = const Duration(seconds: 30),
    ProgressCallback? onProgress,
  }) async {
    final uri = Uri.parse('https://speed.cloudflare.com/__down?bytes=$bytes');
    final req = http.Request('GET', uri);
    final sw = Stopwatch()..start();
    int received = 0;

    try {
      final streamRes = await _client.send(req).timeout(timeout);
      final completer = Completer<void>();
      final sub = streamRes.stream.listen(
        (chunk) {
          received += chunk.length;
          final sec = max(sw.elapsedMicroseconds / 1e6, 0.001);
          final mbps = (received * 8) / (1e6 * sec);
          if (onProgress != null) onProgress(mbps);
        },
        onDone: () => completer.complete(),
        onError: (e) => completer.completeError(e),
        cancelOnError: true,
      );
      await completer.future.timeout(timeout);
      await sub.cancel();
    } catch (_) {
      // ignore, will return NaN below
    } finally {
      sw.stop();
    }

    final seconds = sw.elapsedMicroseconds / 1e6;
    if (received <= 0 || seconds <= 0) return double.nan;
    final mbps = (received * 8) / (1e6 * seconds);
    return mbps;
  }

  // Measure upload speed by posting random bytes to Cloudflare.
  Future<double> measureUploadMbps({
    int bytes = 6 * 1000 * 1000, // 6 MB
    Duration timeout = const Duration(seconds: 30),
    ProgressCallback? onProgress,
  }) async {
    final uri = Uri.parse('https://speed.cloudflare.com/__up?bytes=$bytes');
    final rnd = Random();
    final data = Uint8List.fromList(List<int>.generate(bytes, (_) => rnd.nextInt(256)));

    final sw = Stopwatch()..start();
    try {
      // Since http.post doesn't expose streamed progress easily,
      // we approximate progress assuming linear upload over elapsed time.
      final postFuture = _client.post(uri, body: data).timeout(timeout);
      // Emit periodic progress ticks
      final timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (onProgress != null) {
          final sec = max(sw.elapsedMicroseconds / 1e6, 0.001);
          // optimistic linear estimate: bytes/elapsed
          final mbps = (bytes * 8) / (1e6 * max(sec, 0.001));
          onProgress(mbps);
        }
      });
      await postFuture;
      timer.cancel();
    } catch (_) {
      // ignore, will return NaN below
    } finally {
      sw.stop();
    }

    final seconds = sw.elapsedMicroseconds / 1e6;
    if (seconds <= 0) return double.nan;
    final mbps = (bytes * 8) / (1e6 * seconds);
    return mbps;
  }

  void dispose() {
    _client.close();
  }
}
