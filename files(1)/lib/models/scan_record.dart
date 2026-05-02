import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'product_info.dart';

// ============================================================
// scan_record.dart — everything we know about one scan session
//
// Saved locally (JSON) via [ScanHistory] so History works offline.
// ============================================================

class ScanRecord {
  final String id;
  final String productName;
  final String barcode;
  final String batchNo;
  final String manufacturerName;
  final String manufacturerEmail;

  /// 'safe' | 'moderate' | 'unsafe' | 'unknown'
  final String safetyStatus;
  final int safetyPercent;
  final String detectedColorHex;
  final double hue;
  final double saturation;
  final double value;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String address;
  final String scanDateTimeIso;
  final bool alertSent;
  final String userNotes;

  /// Optional best-before from product data (ISO), for reports.
  final String? bestBeforeIso;

  const ScanRecord({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.batchNo,
    required this.manufacturerName,
    required this.manufacturerEmail,
    required this.safetyStatus,
    required this.safetyPercent,
    required this.detectedColorHex,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.address,
    required this.scanDateTimeIso,
    required this.alertSent,
    required this.userNotes,
    this.bestBeforeIso,
  });

  factory ScanRecord.empty() {
    final now = DateTime.now().toIso8601String();
    return ScanRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: '',
      barcode: '',
      batchNo: '',
      manufacturerName: '',
      manufacturerEmail: '',
      safetyStatus: 'unknown',
      safetyPercent: 0,
      detectedColorHex: '',
      hue: 0,
      saturation: 0,
      value: 0,
      latitude: null,
      longitude: null,
      accuracyMeters: null,
      address: '',
      scanDateTimeIso: now,
      alertSent: false,
      userNotes: '',
      bestBeforeIso: null,
    );
  }

  ScanRecord mergeProduct(ProductInfo p) {
    return copyWith(
      productName: p.productName,
      barcode: p.barcode,
      batchNo: p.batchNo ?? batchNo,
      manufacturerName: p.manufacturerName,
      manufacturerEmail: p.manufacturerEmail,
      bestBeforeIso: p.bestBefore?.toIso8601String() ?? bestBeforeIso,
    );
  }

  ScanRecord mergeGps({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required String address,
  }) {
    return copyWith(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      address: address,
    );
  }

  ScanRecord mergeColorResult({
    required String safetyStatus,
    required int safetyPercent,
    required String detectedColorHex,
    required double hue,
    required double saturation,
    required double value,
  }) {
    return copyWith(
      safetyStatus: safetyStatus,
      safetyPercent: safetyPercent,
      detectedColorHex: detectedColorHex,
      hue: hue,
      saturation: saturation,
      value: value,
      scanDateTimeIso: DateTime.now().toIso8601String(),
    );
  }

  ScanRecord copyWith({
    String? id,
    String? productName,
    String? barcode,
    String? batchNo,
    String? manufacturerName,
    String? manufacturerEmail,
    String? safetyStatus,
    int? safetyPercent,
    String? detectedColorHex,
    double? hue,
    double? saturation,
    double? value,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? address,
    String? scanDateTimeIso,
    bool? alertSent,
    String? userNotes,
    String? bestBeforeIso,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      batchNo: batchNo ?? this.batchNo,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      manufacturerEmail: manufacturerEmail ?? this.manufacturerEmail,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      safetyPercent: safetyPercent ?? this.safetyPercent,
      detectedColorHex: detectedColorHex ?? this.detectedColorHex,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      value: value ?? this.value,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      address: address ?? this.address,
      scanDateTimeIso: scanDateTimeIso ?? this.scanDateTimeIso,
      alertSent: alertSent ?? this.alertSent,
      userNotes: userNotes ?? this.userNotes,
      bestBeforeIso: bestBeforeIso ?? this.bestBeforeIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'barcode': barcode,
        'batchNo': batchNo,
        'manufacturerName': manufacturerName,
        'manufacturerEmail': manufacturerEmail,
        'safetyStatus': safetyStatus,
        'safetyPercent': safetyPercent,
        'detectedColorHex': detectedColorHex,
        'hue': hue,
        'saturation': saturation,
        'value': value,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'address': address,
        'scanDateTimeIso': scanDateTimeIso,
        'alertSent': alertSent,
        'userNotes': userNotes,
        'bestBeforeIso': bestBeforeIso,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> j) => ScanRecord(
        id: j['id'] as String? ?? '',
        productName: j['productName'] as String? ?? '',
        barcode: j['barcode'] as String? ?? '',
        batchNo: j['batchNo'] as String? ?? '',
        manufacturerName: j['manufacturerName'] as String? ?? '',
        manufacturerEmail: j['manufacturerEmail'] as String? ?? '',
        safetyStatus: j['safetyStatus'] as String? ?? 'unknown',
        safetyPercent: (j['safetyPercent'] as num?)?.toInt() ?? 0,
        detectedColorHex: j['detectedColorHex'] as String? ?? '',
        hue: (j['hue'] as num?)?.toDouble() ?? 0,
        saturation: (j['saturation'] as num?)?.toDouble() ?? 0,
        value: (j['value'] as num?)?.toDouble() ?? 0,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        accuracyMeters: (j['accuracyMeters'] as num?)?.toDouble(),
        address: j['address'] as String? ?? '',
        scanDateTimeIso: j['scanDateTimeIso'] as String? ?? '',
        alertSent: j['alertSent'] as bool? ?? false,
        userNotes: j['userNotes'] as String? ?? '',
        bestBeforeIso: j['bestBeforeIso'] as String?,
      );
}

// ── Local persistence (SharedPreferences JSON list) ─────────

class ScanHistory {
  static const _key = 'novagen_scan_history_v1';

  static Future<List<ScanRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => ScanRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Newest scans first (by ISO timestamp string).
  static Future<void> prepend(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final next = [record, ...existing.where((e) => e.id != record.id)];
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> upsert(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final idx = existing.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      existing[idx] = record;
    } else {
      existing.insert(0, record);
    }
    existing.sort((a, b) => b.scanDateTimeIso.compareTo(a.scanDateTimeIso));
    await prefs.setString(
      _key,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> markAlertSent(String id) async {
    final all = await loadAll();
    final next = all
        .map((e) => e.id == id ? e.copyWith(alertSent: true) : e)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
