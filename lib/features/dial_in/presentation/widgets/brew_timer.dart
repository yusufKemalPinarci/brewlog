import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/brew_theme.dart';

/// Basit demleme kronometresi — süreyi kayda yazar; ayrı timer app değil.
class BrewTimer extends StatefulWidget {
  const BrewTimer({
    super.key,
    required this.onApplySeconds,
  });

  final ValueChanged<int> onApplySeconds;

  @override
  State<BrewTimer> createState() => _BrewTimerState();
}

class _BrewTimerState extends State<BrewTimer> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _elapsed = _watch.elapsed.inSeconds);
  }

  void _start() {
    _watch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {});
  }

  void _pause() {
    _watch.stop();
    _ticker?.cancel();
    setState(() => _elapsed = _watch.elapsed.inSeconds);
  }

  void _reset() {
    _watch
      ..stop()
      ..reset();
    _ticker?.cancel();
    setState(() => _elapsed = 0);
  }

  void _apply() {
    final seconds = _watch.elapsed.inSeconds;
    if (seconds <= 0) return;
    widget.onApplySeconds(seconds);
  }

  String get _label {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final running = _watch.isRunning;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrewTheme.roast,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D342E)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kronometre',
              style: GoogleFonts.figtree(
                fontSize: 13,
                color: BrewTheme.mute,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _label,
              style: GoogleFonts.fraunces(
                fontSize: 36,
                height: 1,
                color: BrewTheme.chartreuse,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: running ? _pause : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrewTheme.chartreuse,
                    foregroundColor: BrewTheme.espresso,
                  ),
                  child: Text(running ? 'Duraklat' : 'Başlat'),
                ),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Sıfırla'),
                ),
                OutlinedButton(
                  onPressed: _elapsed > 0 ? _apply : null,
                  child: const Text('Süreye yaz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
