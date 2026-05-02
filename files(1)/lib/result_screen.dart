// ============================================================
// result_screen.dart — human-readable safety readout
//
// Consumes the colour pipeline output, merges it with the active
// [ScanRecord], persists to local history, and routes alerts.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'models/scan_record.dart';
import 'report_screen.dart';
import 'utils/color_utils.dart';

class ResultScreen extends StatefulWidget {
  final ScanRecord scanRecord;
  final ColorScanOutcome outcome;

  const ResultScreen({
    super.key,
    required this.scanRecord,
    required this.outcome,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final ScanRecord _merged;
  bool _saved = false;

  late AnimationController _pctCtrl;
  late Animation<int> _pctAnim;

  @override
  void initState() {
    super.initState();
    _merged = widget.scanRecord.mergeColorResult(
      safetyStatus: widget.outcome.status,
      safetyPercent: widget.outcome.safetyPercent,
      detectedColorHex: widget.outcome.hexCode,
      hue: widget.outcome.hue,
      saturation: widget.outcome.saturation,
      value: widget.outcome.value,
    );

    _pctCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pctAnim = IntTween(begin: 0, end: _merged.safetyPercent).animate(
      CurvedAnimation(parent: _pctCtrl, curve: Curves.easeOutCubic),
    );
    _pctCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_saved) return;
      _saved = true;
      await ScanHistory.prepend(_merged);
    });
  }

  @override
  void dispose() {
    _pctCtrl.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (_merged.safetyStatus) {
      case 'safe':
        return kSafe;
      case 'moderate':
        return kModerate;
      default:
        return kUnsafe;
    }
  }

  List<Color> get _gradientTop {
    switch (_merged.safetyStatus) {
      case 'safe':
        return const [Color(0xFF0D2137), kNavy];
      case 'moderate':
        return const [Color(0xFF1F1500), kNavy];
      default:
        return const [Color(0xFF1F0505), kNavy];
    }
  }

  String get _badge {
    switch (_merged.safetyStatus) {
      case 'safe':
        return 'SAFE TO EAT';
      case 'moderate':
        return 'CONSUME SOON';
      default:
        return 'DO NOT EAT';
    }
  }

  IconData get _icon {
    switch (_merged.safetyStatus) {
      case 'safe':
        return Icons.check_circle_rounded;
      case 'moderate':
        return Icons.schedule_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String get _sub {
    switch (_merged.safetyStatus) {
      case 'safe':
        return 'Normalized colour landed in the safe (blue) band.';
      case 'moderate':
        return 'Green tones mean the freshness window is closing.';
      default:
        return 'Warm hues or flattened saturation suggest the ink has reacted.';
    }
  }

  void _scanAgain(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).pushNamed('/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientTop,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Result',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accent),
                      ),
                      child: Text(
                        'NovaGen',
                        style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _accent.withAlpha(90), blurRadius: 40, spreadRadius: 4),
                  ],
                ),
                child: Icon(_icon, size: 64, color: _accent),
              ),
              const SizedBox(height: 16),
              Text(
                _badge,
                style: TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _pctAnim,
                builder: (_, __) => Text(
                  '${_pctAnim.value}%',
                  style: TextStyle(
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: _accent.withAlpha(220), blurRadius: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: widget.outcome.displayColor,
                    radius: 17,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _merged.detectedColorHex.isEmpty ? widget.outcome.hexCode : _merged.detectedColorHex,
                    style: const TextStyle(
                      fontFeatures: [],
                      letterSpacing: 1.8,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'HSV(ref) • H ${_merged.hue.toStringAsFixed(1)}°  '
                'S ${(_merged.saturation * 100).toStringAsFixed(1)}%  '
                'V ${(_merged.value * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withAlpha(24),
                    border: Border.all(color: _accent.withAlpha(99)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icon, color: _accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.outcome.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sub,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReportScreen(record: _merged),
                            ),
                          );
                        },
                        child: const Text('Alert Manufacturer'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _scanAgain(context),
                        child: const Text('Save & Scan Again'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat.yMMMd().add_jm().format(
                  DateTime.tryParse(_merged.scanDateTimeIso) ?? DateTime.now(),
                ),
                style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
