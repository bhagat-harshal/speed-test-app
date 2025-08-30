import 'dart:convert';

class SpeedResult {
  final int? id;
  final DateTime timestamp;
  final String connectionType; // e.g., Wi‑Fi, Mobile, Ethernet, None
  final double pingMs;
  final double downloadMbps;
  final double uploadMbps;

  const SpeedResult({
    this.id,
    required this.timestamp,
    required this.connectionType,
    required this.pingMs,
    required this.downloadMbps,
    required this.uploadMbps,
  });

  SpeedResult copyWith({
    int? id,
    DateTime? timestamp,
    String? connectionType,
    double? pingMs,
    double? downloadMbps,
    double? uploadMbps,
  }) {
    return SpeedResult(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      connectionType: connectionType ?? this.connectionType,
      pingMs: pingMs ?? this.pingMs,
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'connectionType': connectionType,
      'pingMs': pingMs,
      'downloadMbps': downloadMbps,
      'uploadMbps': uploadMbps,
    };
  }

  factory SpeedResult.fromMap(Map<String, dynamic> map) {
    return SpeedResult(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      connectionType: map['connectionType'] as String,
      pingMs: (map['pingMs'] as num).toDouble(),
      downloadMbps: (map['downloadMbps'] as num).toDouble(),
      uploadMbps: (map['uploadMbps'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());
  factory SpeedResult.fromJson(String source) => SpeedResult.fromMap(json.decode(source) as Map<String, dynamic>);
}
