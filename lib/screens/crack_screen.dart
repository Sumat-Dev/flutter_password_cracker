import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_password_cracker/rust/api.dart';
import 'package:flutter_password_cracker/widgets/crack_progress_widget.dart';

class CrackScreen extends StatefulWidget {
  const CrackScreen({super.key});

  @override
  State<CrackScreen> createState() => _CrackScreenState();
}

class _CrackScreenState extends State<CrackScreen> {
  final _controller = TextEditingController();

  String? _hash;
  CrackProgress? _latest;
  bool _running = false;
  bool _found = false;

  static const _purple = Color(0xFF7F77DD);
  static const _teal = Color(0xFF5DCAA5);
  static const _red = Color(0xFFE24B4A);
  static const _panel = Color(0xFF1A1A1F);
  static const _border = Color(0xFF2A2A35);
  static const _muted = Color(0xFF888888);

  Future<void> _hashAndCrack() async {
    final pw = _controller.text.trim();
    if (pw.isEmpty) return;
    if (pw.length > 5) {
      _showSnack('Keep password ≤ 5 chars for a fast demo');
      return;
    }

    // Step 1 — hash via Rust (sync)
    final hash = hashString(input: pw);
    setState(() {
      _hash = hash;
      _running = true;
      _found = false;
      _latest = null;
    });

    // Step 2 — stream crack progress
    bruteForceCrack(targetHash: hash).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _latest = progress;
          if (progress.isFound) {
            _running = false;
            _found = true;
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _running = false);
        _showSnack('Error: $e');
      },
    );
  }

  void _reset() {
    setState(() {
      _hash = null;
      _latest = null;
      _running = false;
      _found = false;
      _controller.clear();
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 8),
              const Text(
                'HashCrack',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'rust · sha-256 · rayon',
                style: TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Input
              const Text(
                'PASSWORD INPUT',
                style: TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontFamily: 'monospace',
                  letterSpacing: 0.08,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                enabled: !_running,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z]')),
                ],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'e.g. abc',
                  hintStyle: const TextStyle(color: _muted, letterSpacing: 0),
                  filled: true,
                  fillColor: _panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _purple, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hash display
              if (_hash != null) ...[
                const Text(
                  'SHA-256 HASH',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontFamily: 'monospace',
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.5),
                  ),
                  child: Text(
                    _hash!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _teal,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Button
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: _running
                        ? null
                        : (_found ? _reset : _hashAndCrack),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _found
                          ? _teal
                          : (_running ? _red : _purple),
                      disabledBackgroundColor: _red.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _found
                          ? 'Reset'
                          : _running
                          ? 'Cracking...'
                          : 'Hash & Start Cracking',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress widget
              if (_latest != null || _running)
                CrackProgressWidget(progress: _latest, running: _running),
            ],
          ),
        ),
      ),
    );
  }
}
