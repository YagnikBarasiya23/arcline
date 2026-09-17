import 'package:arcline/arcline.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ArclineDemo());

const _bg = Color(0xFF050505);
const _panel = Color(0xFF0E0E10);
const _line = Color(0x1AFFFFFF);
const _muted = Color(0xFFA1A1AA);
const _accent = Color(0xFFD9F99D);

class ArclineDemo extends StatelessWidget {
  const ArclineDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcline — animated arc gauge for Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, surface: _panel),
        sliderTheme: const SliderThemeData(activeTrackColor: _accent, thumbColor: _accent, inactiveTrackColor: _line),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  static const _target = 2454.0;
  double _eaten = 1745;
  double _sweep = 240;
  double _thickness = 22;
  double _damping = 14;

  void _add(double kcal) => setState(() => _eaten = (_eaten + kcal).clamp(0, _target * 2));

  @override
  Widget build(BuildContext context) {
    final remaining = _target - _eaten;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _Panel(
                        width: 440,
                        child: Column(
                          children: [
                            Arcline(
                              value: _eaten,
                              max: _target,
                              size: 280,
                              thickness: _thickness,
                              sweepDegrees: _sweep,
                              damping: _damping,
                              markers: const [_target * 0.8],
                              semanticLabel: 'Calories today',
                              center: (context, value) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${value.round()}', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.5, fontFeatures: [FontFeature.tabularFigures()])),
                                  const Text('of 2,454 kcal', style: TextStyle(color: _muted)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remaining >= 0 ? '${remaining.round()} kcal left today' : '${(-remaining).round()} kcal over target',
                              style: TextStyle(color: remaining >= 0 ? _muted : const Color(0xFFFB923C), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _Chip(label: '+ Snack 180', onTap: () => _add(180)),
                                _Chip(label: '+ Lunch 620', onTap: () => _add(620)),
                                _Chip(label: '− 250', onTap: () => _add(-250)),
                                _Chip(label: 'Reset', onTap: () => setState(() => _eaten = 0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _Panel(
                        width: 440,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Feel', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                            _Setting(label: 'Sweep', value: '${_sweep.round()}°', slider: Slider(value: _sweep, min: 120, max: 360, onChanged: (v) => setState(() => _sweep = v))),
                            _Setting(label: 'Thickness', value: '${_thickness.round()} px', slider: Slider(value: _thickness, min: 6, max: 40, onChanged: (v) => setState(() => _thickness = v))),
                            _Setting(label: 'Damping', value: _damping.toStringAsFixed(0), slider: Slider(value: _damping, min: 4, max: 30, onChanged: (v) => setState(() => _damping = v))),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap the buttons quickly — the arc keeps its momentum instead of restarting. '
                              'Go past the target to see the second lap. The tick marks 80% of the goal.',
                              style: TextStyle(color: _muted, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _Panel(
                    child: Wrap(
                      spacing: 28,
                      runSpacing: 20,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        _Mini(label: 'Steps', value: 7420, max: 10000, unit: '', colors: [Color(0xFF93C5FD), Color(0xFFC4B5FD)]),
                        _Mini(label: 'Water', value: 1.8, max: 2.5, unit: ' L', decimals: 1, colors: [Color(0xFF67E8F9), Color(0xFF7DD3FC)]),
                        _Mini(label: 'Sleep', value: 8.4, max: 8, unit: ' h', decimals: 1, colors: [Color(0xFFF9A8D4), Color(0xFFFDA4AF)]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('MIT © 2026 Yagnik Barasiya · github.com/YagnikBarasiya23/arcline', style: TextStyle(color: _muted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ARCLINE · FLUTTER', style: TextStyle(color: Color(0xFF71717A), letterSpacing: 3.5, fontSize: 12, fontWeight: FontWeight.w600)),
        SizedBox(height: 12),
        Text('Progress that springs,\nnot ticks.', style: TextStyle(fontSize: 44, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.8)),
        SizedBox(height: 14),
        Text(
          'An arc gauge with a spring-driven fill, a second lap past the target, milestone ticks and a centre that counts along.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.6),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x38FFFFFF)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting({required this.label, required this.value, required this.slider});

  final String label;
  final String value;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text(label, style: const TextStyle(color: _muted)), const Spacer(), Text(value)]),
          slider,
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.max, required this.unit, required this.colors, this.decimals = 0});

  final String label;
  final double value;
  final double max;
  final String unit;
  final List<Color> colors;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Arcline(
          value: value,
          max: max,
          size: 150,
          thickness: 12,
          sweepDegrees: 360,
          colors: colors,
          semanticLabel: label,
          center: (context, v) => Text('${v.toStringAsFixed(decimals)}$unit', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: _muted)),
      ],
    );
  }
}
