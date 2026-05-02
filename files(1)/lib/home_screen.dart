import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'history_screen.dart';

// ============================================================
// home_screen.dart — NovaGen landing hub
//
// Explains SafeInk visually and routes users into the scanner hub
// or their saved timeline.
// ============================================================

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              /// Brand header ------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ngBadge(context),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Nova',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Gen',
                              style: TextStyle(
                                color: kOrange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SAFEINK SCANNER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                'INNOVATE. GENERATE. ELEVATE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kOrange.withAlpha(217),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 18),
              _gradientDivider(),

              const SizedBox(height: 18),

              Text(
                'SafeInk Food Scanner',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 20),
              ),

              const SizedBox(height: 24),

              _stepRow(context),

              const Spacer(),

              /// Primary CTA -------------------------------------------------
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/scanner');
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  splashFactory: InkSplash.splashFactory,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: kOrange,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'START SCANNING',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.8),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                child: const Text(
                  'History',
                  style: TextStyle(
                    letterSpacing: 1.8,
                    color: kBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'Powered by NovaGen',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(64), fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Helpers ────────────────────────

  Widget _ngBadge(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: kDarkBlue,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kBlue.withAlpha(77),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Align(
        alignment: Alignment.center,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: 'N', style: TextStyle(color: kBlue)),
            TextSpan(text: 'G', style: TextStyle(color: kOrange)),
          ], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _gradientDivider() {
    return SizedBox(
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [kBlue, kOrange.withAlpha(220)],
          ),
        ),
      ),
    );
  }

  Widget _stepRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _StepCard(step: '1', title: 'Align', caption: 'Line up barcode or ring'),
        _StepCard(step: '2', title: 'Scan', caption: 'Capture product data'),
        _StepCard(step: '3', title: 'Result', caption: 'Share manufacturer alert'),
      ],
    );
  }
}

/// Compact step tile with numbered halo (alternating brand colours).
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String caption;

  const _StepCard({
    required this.step,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final bool blueStep = step == '1' || step == '3';
    final Color halo = blueStep ? kBlue : kOrange;

    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: kDarkBlue,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: halo.withAlpha(90), blurRadius: 28)],
              border: Border.all(color: halo.withAlpha(180)),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: TextStyle(color: halo, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, height: 1.25),
          ),
        ],
      ),
    );
  }
}
