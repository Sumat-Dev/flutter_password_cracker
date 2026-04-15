import 'package:flutter/material.dart';
import '../src/rust/api.dart';

class CrackProgressWidget extends StatelessWidget {
  final CrackProgress? progress;
  final bool running;

  const CrackProgressWidget({
    super.key,
    required this.progress,
    required this.running,
  });

  static const _purple = Color(0xFF7F77DD);
  static const _teal = Color(0xFF5DCAA5);
  static const _amber = Color(0xFFEF9F27);
  static const _border = Color(0xFF2A2A35);
  static const _muted = Color(0xFF888888);
  static const _bg = Color(0xFF0A0A0C);

  String _fmtAttempts(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _fmtSpeed(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)} MH/s';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} KH/s';
    return '${n.toStringAsFixed(0)} H/s';
  }

  @override
  Widget build(BuildContext context) {
    final attempts = (progress?.totalAttempts ?? BigInt.zero).toInt();
    final speed = (progress?.hashesPerSec ?? 0.0);
    final elapsed = (progress?.elapsedSecs ?? 0.0);
    final currentGuess = progress?.currentAttempt ?? '';
    final isFound = progress?.isFound ?? false;
    final result = progress?.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            _StatCard(
              label: 'ATTEMPTS',
              value: _fmtAttempts(attempts),
              color: isFound ? _teal : _purple,
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'SPEED',
              value: _fmtSpeed(speed),
              color: isFound ? _teal : _amber,
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'ELAPSED',
              value: '${elapsed.toStringAsFixed(1)}s',
              color: isFound ? _teal : _purple,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Thread indicators
        Row(
          children: List.generate(
            8,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 7 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: running
                      ? _purple.withValues(alpha: 0.4 + (i % 3) * 0.2)
                      : isFound
                      ? _teal
                      : _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          running
              ? '8 rayon threads · running'
              : isFound
              ? '8 rayon threads · done'
              : '8 rayon threads · idle',
          style: const TextStyle(
            fontSize: 9,
            color: _muted,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),

        // Terminal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentGuess.isNotEmpty)
                _TermLine(
                  prefix: '·',
                  prefixColor: _muted,
                  text: 'testing: ',
                  value: currentGuess,
                  valueColor: Colors.white70,
                ),
              _TermLine(
                prefix: '→',
                prefixColor: _purple,
                text: 'attempts: ',
                value: _fmtAttempts(attempts),
                valueColor: _purple,
              ),
              _TermLine(
                prefix: '→',
                prefixColor: _purple,
                text: 'speed: ',
                value: _fmtSpeed(speed),
                valueColor: _amber,
              ),
              if (isFound && result != null)
                _TermLine(
                  prefix: '✓',
                  prefixColor: _teal,
                  text: 'FOUND: ',
                  value: '"$result" in ${elapsed.toStringAsFixed(2)}s',
                  valueColor: _teal,
                ),
              if (running && !isFound)
                _TermLine(
                  prefix: '⟳',
                  prefixColor: _amber,
                  text: 'status: ',
                  value: 'searching...',
                  valueColor: _amber,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Result banner
        if (isFound && result != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2820),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1D9E75), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✓ PASSWORD FOUND',
                  style: TextStyle(
                    fontSize: 10,
                    color: _teal,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmtAttempts(attempts)} attempts · ${_fmtSpeed(speed)} · ${elapsed.toStringAsFixed(2)}s',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _muted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A35), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF888888),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final String prefix;
  final Color prefixColor;
  final String text;
  final String value;
  final Color valueColor;

  const _TermLine({
    required this.prefix,
    required this.prefixColor,
    required this.text,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$prefix ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: prefixColor,
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
