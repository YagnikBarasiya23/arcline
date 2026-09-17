import 'dart:math' as math;

import 'package:arcline/arcline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

ArclinePainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.descendant(of: find.byType(Arcline), matching: find.byType(CustomPaint)))
    .map((paint) => paint.painter)
    .whereType<ArclinePainter>()
    .single;

void main() {
  group('ArcFill', () {
    test('splits a value into the first lap and the over-target lap', () {
      expect(ArcFill.of(0, 100), const ArcFill(0, 0));
      expect(ArcFill.of(50, 100), const ArcFill(0.5, 0));
      expect(ArcFill.of(100, 100), const ArcFill(1, 0));
      expect(ArcFill.of(130, 100), const ArcFill(1, 0.30000000000000004));
      expect(ArcFill.of(500, 100), const ArcFill(1, 1));
    });

    test('never goes negative and ignores invalid input', () {
      expect(ArcFill.of(-20, 100), const ArcFill(0, 0));
      expect(ArcFill.of(double.nan, 100), const ArcFill(0, 0));
      expect(ArcFill.of(10, 0), const ArcFill(0, 0));
      expect(ArcFill.of(130, 100).isOver, isTrue);
    });
  });

  group('geometry', () {
    test('the gap is centred at the bottom', () {
      // A 240° arc starts 150° clockwise from the positive x axis and ends at 30°.
      final start = arcStart(240 * math.pi / 180);
      expect(start, closeTo(150 * math.pi / 180, 1e-9));
      expect((start + 240 * math.pi / 180) % (2 * math.pi), closeTo(30 * math.pi / 180, 1e-9));
      expect(arcStart(2 * math.pi), closeTo(math.pi / 2, 1e-9));
    });

    test('points lie on the circle', () {
      final p = arcPoint(const Offset(10, 10), 5, math.pi / 2);
      expect(p.dx, closeTo(10, 1e-9));
      expect(p.dy, closeTo(15, 1e-9));
    });
  });

  group('Arcline', () {
    testWidgets('fills from zero to the value on mount', (tester) async {
      await tester.pumpWidget(_app(const Arcline(value: 60, max: 100)));
      expect(_painter(tester).fill.fill, 0);
      await tester.pump(const Duration(milliseconds: 150));
      final mid = _painter(tester).fill.fill;
      expect(mid, greaterThan(0));
      await tester.pumpAndSettle();
      expect(_painter(tester).fill.fill, closeTo(0.6, 0.001));
    });

    testWidgets('springs to a new value and shows the over-target lap', (tester) async {
      await tester.pumpWidget(_app(const Arcline(value: 60, max: 100, animateOnMount: false)));
      expect(_painter(tester).fill.fill, 0.6);
      await tester.pumpWidget(_app(const Arcline(value: 125, max: 100, animateOnMount: false)));
      await tester.pumpAndSettle();
      final fill = _painter(tester).fill;
      expect(fill.fill, 1);
      expect(fill.over, closeTo(0.25, 0.001));
    });

    testWidgets('the centre builder counts along with the animation', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_app(Arcline(
        value: 2000,
        max: 2500,
        center: (context, value) {
          seen.add(value);
          return Text('${value.round()} kcal');
        },
      )));
      await tester.pumpAndSettle();
      expect(find.text('2000 kcal'), findsOneWidget);
      expect(seen.where((v) => v > 0 && v < 1900), isNotEmpty);
    });

    testWidgets('reduced motion jumps straight to the value', (tester) async {
      await tester.pumpWidget(_app(const Arcline(value: 40, max: 80), reduceMotion: true));
      await tester.pump();
      expect(_painter(tester).fill.fill, 0.5);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('screen readers get the label and percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(Arcline(
        value: 1745,
        max: 2454,
        semanticLabel: 'Calories today',
        center: (context, value) => Text('${value.round()}'),
      )));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Calories today'), findsOneWidget);
      final data = tester.getSemantics(find.bySemanticsLabel('Calories today'));
      expect(data.value, '71%');
      handle.dispose();
    });
  });
}
