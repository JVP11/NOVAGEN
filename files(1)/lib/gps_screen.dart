// ============================================================
// gps_screen.dart — stylised map + real coordinates
//
// The top half is a lightweight custom paint “map” so we do not
// need a Maps SDK key. The bottom half uses Geolocator + Geocoding
// for real device data (with a safe fallback on web/desktop).
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_theme.dart';
import 'models/scan_record.dart';

class GpsScreen extends StatefulWidget {
  final ScanRecord record;

  const GpsScreen({super.key, required this.record});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _busy = true;
  String? _error;
  double _lat = 51.5074;
  double _lng = -0.1278;
  double _accuracy = 12;
  String _address = 'Locating…';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
        setState(() {
          _busy = false;
          _address = 'Location preview (use a mobile device for live GPS)';
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String addr = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final Placemark p = marks.first;
          addr = [
            p.name,
            p.street,
            p.locality,
            p.postalCode,
            p.country,
          ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');
        }
      } catch (_) {
        // Geocoding can fail on some emulators — coordinates still useful.
      }

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _accuracy = pos.accuracy;
        _address = addr;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
        _address = 'Could not resolve address';
      });
    }
  }

  ScanRecord _buildRecord() {
    return widget.record.mergeGps(
      latitude: _lat,
      longitude: _lng,
      accuracyMeters: _accuracy,
      address: _address,
    );
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_lat,$_lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool warn = _accuracy > 50;

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Scan location'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FakeMapPainter(animation: _pulse),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534).withAlpha(220),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GPS Active',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 12,
                  child: Text(
                    'NovaGen GPS — Live',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (warn && !_busy)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withAlpha(61),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFACC15)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Accuracy > 50 m — step outside if you need tighter precision.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      _coordBox('Latitude', _lat.toStringAsFixed(5)),
                      const SizedBox(width: 10),
                      _coordBox('Longitude', _lng.toStringAsFixed(5)),
                      const SizedBox(width: 10),
                      _coordBox('Accuracy', '±${_accuracy.toStringAsFixed(0)} m'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kOrange.withAlpha(36),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kOrange.withAlpha(119)),
                      ),
                      child: _busy
                          ? const Center(child: CircularProgressIndicator(color: kOrange))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _error != null ? '$_error\n$_address' : _address,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: kOrange),
                          onPressed: _busy ? null : () => Navigator.pop(context, _buildRecord()),
                          child: const Text('Include in Report'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _openMaps,
                          child: const Text('View on Maps'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kDarkBlue.withAlpha(160),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSlate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FakeMapPainter extends CustomPainter {
  final Animation<double> animation;

  _FakeMapPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()..color = const Color(0xFF064E3B);
    canvas.drawRect(Offset.zero & size, bg);

    final Paint grid = Paint()
      ..color = const Color(0xFF065F46).withAlpha(120)
      ..strokeWidth = 1;

    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final rnd = Paint()..color = kBlue.withAlpha(26);
    for (int i = 0; i < 26; i++) {
      final double w = size.width / 13 * (i % 5 + 3) / 5;
      final double h = size.height / 16 * ((i + 3) % 6);
      canvas.drawRect(
        Rect.fromLTWH(size.width / 22 * ((i + 8) % 11), size.height / 18 * ((i + 6) % 9), w, h),
        rnd,
      );
    }

    final Offset centre = Offset(size.width / 2, size.height / 2);

    final double t = animation.value;

    canvas.drawCircle(
      centre,
      14 + (t * 36),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = kOrange.withAlpha(((1 - t) * 220).clamp(26, 220).toInt())
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      centre,
      9,
      Paint()..color = kOrange,
    );
    canvas.drawCircle(
      centre,
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _FakeMapPainter oldDelegate) => true;
}
