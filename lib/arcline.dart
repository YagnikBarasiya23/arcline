/// Arcline — an animated arc gauge. MIT © 2026 Yagnik Barasiya.
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// How much of the arc a value fills.
///
/// [fill] is the share of the first lap (0–1). [over] is how far past the
/// maximum the value goes, as a share of a second lap (0–1).
@immutable
class ArcFill {
  const ArcFill(this.fill, this.over);

  factory ArcFill.of(double value, double max) {
    if (max <= 0 || value.isNaN) return const ArcFill(0, 0);
    final ratio = value / max;
    return ArcFill(ratio.clamp(0.0, 1.0), (ratio - 1).clamp(0.0, 1.0));
  }

  final double fill;
  final double over;

  bool get isOver => over > 0;

  @override
  bool operator ==(Object other) => other is ArcFill && other.fill == fill && other.over == over;

  @override
  int get hashCode => Object.hash(fill, over);

  @override
  String toString() => 'ArcFill($fill, over: $over)';
}

/// Where an arc of [sweep] radians starts so its gap is centred at the bottom.
double arcStart(double sweep) => math.pi / 2 + (2 * math.pi - sweep) / 2;

/// The point on a circle of [radius] around [center] at [angle] radians.
Offset arcPoint(Offset center, double radius, double angle) =>
    center + Offset(math.cos(angle), math.sin(angle)) * radius;

/// A gauge that springs to [value] out of [max].
///
/// ```dart
/// Arcline(
///   value: 1745,
///   max: 2454,
///   center: (context, value) => Text('${value.round()} kcal'),
/// )
/// ```
class Arcline extends StatefulWidget {
  const Arcline({
    super.key,
    required this.value,
    required this.max,
    this.size = 220,
    this.thickness = 18,
    this.sweepDegrees = 240,
    this.colors = const [Color(0xFF86EFAC), Color(0xFFD9F99D)],
    this.trackColor = const Color(0x1FFFFFFF),
    this.overColor = const Color(0xFFFB923C),
    this.markers = const [],
    this.markerColor = const Color(0x99FFFFFF),
    this.center,
    this.stiffness = 90,
    this.damping = 14,
    this.animateOnMount = true,
    this.semanticLabel,
  }) : assert(max > 0),
       assert(sweepDegrees > 0 && sweepDegrees <= 360);

  /// The current amount. Values above [max] draw a second, over-target lap.
  final double value;

  /// The amount that fills the arc once.
  final double max;

  /// Width and height of the gauge.
  final double size;

  /// Stroke width of the arc.
  final double thickness;

  /// How much of the circle the arc covers, in degrees.
  final double sweepDegrees;

  /// The fill runs through these colours from start to end.
  final List<Color> colors;

  /// Colour of the unfilled track.
  final Color trackColor;

  /// Colour of the lap drawn once [value] passes [max].
  final Color overColor;

  /// Values to mark with a small tick outside the arc, such as a target.
  final List<double> markers;

  /// Colour of the marker ticks.
  final Color markerColor;

  /// Builds the middle of the gauge from the value as it animates.
  final Widget Function(BuildContext context, double value)? center;

  /// Spring stiffness. Higher reaches the value sooner.
  final double stiffness;

  /// Spring damping. Lower overshoots and wobbles more.
  final double damping;

  /// Whether the gauge fills from zero the first time it appears.
  final bool animateOnMount;

  /// What the gauge measures, read by screen readers with the percentage.
  final String? semanticLabel;

  @override
  State<Arcline> createState() => _ArclineState();
}

class _ArclineState extends State<Arcline> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller.value = widget.animateOnMount ? 0 : widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first fill needs MediaQuery, which isn't available in initState.
    if (!_started) {
      _started = true;
      _go(widget.value);
    }
  }

  @override
  void didUpdateWidget(Arcline old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.stiffness != widget.stiffness || old.damping != widget.damping) {
      _go(widget.value);
    }
  }

  void _go(double target) {
    if (_controller.value == target && !_controller.isAnimating) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = target;
      return;
    }
    // Starting from the current position and velocity keeps rapid changes smooth.
    final spring = SpringDescription(mass: 1, stiffness: widget.stiffness, damping: widget.damping);
    _controller
        .animateWith(
          SpringSimulation(
            spring,
            _controller.value,
            target,
            _controller.velocity,
            tolerance: Tolerance(distance: widget.max / 2000, velocity: widget.max / 500),
          ),
        )
        // The spring stops within its tolerance; land exactly on the value so labels read true.
        .then((_) {
          if (mounted && !_controller.isAnimating && widget.value == target) _controller.value = target;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.value / widget.max * 100).round();
    return Semantics(
      label: widget.semanticLabel ?? 'Progress',
      value: '$percent%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = _controller.value;
            return CustomPaint(
              painter: ArclinePainter(
                fill: ArcFill.of(value, widget.max),
                max: widget.max,
                thickness: widget.thickness,
                sweep: widget.sweepDegrees * math.pi / 180,
                colors: widget.colors,
                trackColor: widget.trackColor,
                overColor: widget.overColor,
                markers: widget.markers,
                markerColor: widget.markerColor,
              ),
              child: widget.center == null
                  ? null
                  : Center(child: ExcludeSemantics(child: widget.center!(context, value))),
            );
          },
        ),
      ),
    );
  }
}

/// Paints the track, fill, over-target lap, markers and the glowing end knob.
class ArclinePainter extends CustomPainter {
  ArclinePainter({
    required this.fill,
    required this.max,
    required this.thickness,
    required this.sweep,
    required this.colors,
    required this.trackColor,
    required this.overColor,
    required this.markers,
    required this.markerColor,
  });

  final ArcFill fill;
  final double max;
  final double thickness;
  final double sweep;
  final List<Color> colors;
  final Color trackColor;
  final Color overColor;
  final List<double> markers;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Leave room for the knob glow and marker ticks outside the stroke.
    final radius = size.shortestSide / 2 - thickness * 1.05;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = arcStart(sweep);

    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, start, sweep, false, stroke(trackColor));

    for (final marker in markers) {
      final angle = start + sweep * (marker / max).clamp(0.0, 1.0);
      canvas.drawLine(
        arcPoint(center, radius + thickness * 0.65, angle),
        arcPoint(center, radius + thickness * 1.0, angle),
        Paint()
          ..color = markerColor
          ..strokeWidth = math.max(2, thickness / 7)
          ..strokeCap = StrokeCap.round,
      );
    }

    // A spring can dip just below zero; draw nothing rather than a backwards arc.
    final fillSweep = sweep * fill.fill;
    if (fillSweep > 0.001) {
      // Start the gradient a cap's width early so the rounded start takes the first colour
      // instead of wrapping round to the last one.
      final cap = (thickness / 2) / radius;
      final gradient = SweepGradient(
        startAngle: cap,
        endAngle: cap + math.max(fillSweep, 0.01),
        colors: colors.length > 1 ? colors : [colors.first, colors.first],
        transform: GradientRotation(start - cap),
      );
      canvas.drawArc(rect, start, fillSweep, false, stroke(colors.first)..shader = gradient.createShader(rect));
    }

    if (fill.isOver) {
      canvas.drawArc(rect, start, sweep * fill.over, false, stroke(overColor.withValues(alpha: 0.9)));
    }

    // A knob at the leading edge, with a soft glow in its colour.
    if (fillSweep > 0.001) {
      final lead = fill.isOver ? start + sweep * fill.over : start + fillSweep;
      final knobColor = fill.isOver ? overColor : colors.last;
      final point = arcPoint(center, radius, lead);
      canvas.drawCircle(
        point,
        thickness * 0.75,
        Paint()
          ..color = knobColor.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.5),
      );
      canvas.drawCircle(point, thickness * 0.34, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(ArclinePainter old) =>
      old.fill != fill ||
      old.max != max ||
      old.thickness != thickness ||
      old.sweep != sweep ||
      old.trackColor != trackColor ||
      old.overColor != overColor ||
      old.markerColor != markerColor ||
      !_listEquals(old.colors, colors) ||
      !_listEquals(old.markers, markers);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
