import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petrotools/main.dart';
import 'package:petrotools/models/well_data.dart';
import 'package:petrotools/screens/ipr_screen.dart';
import 'package:petrotools/utils/nodal_calculations.dart';

void main() {
  testWidgets('Home screen lists the nodal analysis tools', (tester) async {
    await tester.pumpWidget(const PetroToolsApp());

    expect(find.text('PetroTools'), findsOneWidget);
    expect(find.text('IPR Calculator'), findsOneWidget);
    // Hidden for now — not shown on the home screen.
    expect(find.text('Operating Point'), findsNothing);
  });

  testWidgets('IPR inputs keep their state after scrolling away and back',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IprScreen()));

    await tester.tap(find.text('PI known'));
    await tester.pumpAndSettle();
    expect(find.text('Productivity Index (J)'), findsOneWidget);

    final scrollable = find.byType(SingleChildScrollView);
    await tester.drag(scrollable, const Offset(0, -1000));
    await tester.pump();
    await tester.drag(scrollable, const Offset(0, 1000));
    await tester.pumpAndSettle();

    // Mode selection (and field values) must survive the round trip.
    expect(find.text('Productivity Index (J)'), findsOneWidget);
  });

  group('IPR from a well test (no PI)', () {
    test('saturated reservoir (Pr ≤ Pb) uses pure Vogel', () {
      final res = NodalCalculations.buildIprFromTest(
          pr: 2400, pb: 2500, qTest: 500, pwfTest: 1800);
      final m = res.model;
      // r = 0.75 → f = 1 − 0.15 − 0.45 = 0.4 → qmax = 500 / 0.4 = 1250
      expect(m.isSaturated, isTrue);
      expect(m.qMax, closeTo(1250, 0.5));
      expect(NodalCalculations.iprFlowRate(m, 2400), closeTo(0, 1e-9));
      expect(NodalCalculations.iprFlowRate(m, 0), closeTo(1250, 0.5));
      expect(NodalCalculations.iprFlowRate(m, 1800), closeTo(500, 0.5));
      expect(res.steps, isNotEmpty);
    });

    test('undersaturated with test above Pb (linear segment)', () {
      final res = NodalCalculations.buildIprFromTest(
          pr: 3000, pb: 2000, qTest: 600, pwfTest: 2400);
      final m = res.model;
      // J = 600/600 = 1, qb = 1000, qv = 2000/1.8 = 1111.1
      expect(m.productivityIndex, closeTo(1.0, 1e-9));
      expect(m.qb, closeTo(1000, 1e-6));
      expect(m.qMax, closeTo(1000 + 2000 / 1.8, 1e-6));
      expect(NodalCalculations.iprFlowRate(m, 2500), closeTo(500, 1e-6));
    });

    test('undersaturated with test below Pb (Vogel segment)', () {
      final res = NodalCalculations.buildIprFromTest(
          pr: 3000, pb: 2000, qTest: 1500, pwfTest: 1000);
      final m = res.model;
      // The built IPR must reproduce the test point.
      expect(NodalCalculations.iprFlowRate(m, 1000), closeTo(1500, 1e-6));
      expect(m.isSaturated, isFalse);
    });
  });

  group('IPR from a known PI', () {
    test('matches the test-derived model with the same J', () {
      final res = NodalCalculations.buildIprFromPI(pr: 3000, pb: 2000, j: 1.0);
      expect(res.model.qb, closeTo(1000, 1e-6));
      expect(res.model.qMax, closeTo(1000 + 2000 / 1.8, 1e-6));
    });

    test('saturated: qmax = J·Pr/1.8', () {
      final res = NodalCalculations.buildIprFromPI(pr: 1800, pb: 2000, j: 2.0);
      expect(res.model.qMax, closeTo(2.0 * 1800 / 1.8, 1e-9));
    });
  });

  group('Composite IPR consistency', () {
    final m = NodalCalculations.buildIprFromTest(
            pr: 3000, pb: 2000, qTest: 600, pwfTest: 2400)
        .model;

    test('iprPwf inverts iprFlowRate in the linear region', () {
      const pwf = 2600.0;
      final q = NodalCalculations.iprFlowRate(m, pwf);
      expect(NodalCalculations.iprPwf(m, q), closeTo(pwf, 1e-6));
    });

    test('iprPwf inverts iprFlowRate in the Vogel region', () {
      const pwf = 1200.0;
      final q = NodalCalculations.iprFlowRate(m, pwf);
      expect(NodalCalculations.iprPwf(m, q), closeTo(pwf, 1e-6));
    });

    test('curve is continuous at the bubble point', () {
      final above = NodalCalculations.iprFlowRate(m, 2000.0001);
      final below = NodalCalculations.iprFlowRate(m, 1999.9999);
      expect(above, closeTo(below, 0.01));
    });
  });

  group('Operating point', () {
    const tpc = TpcModel(
      wellheadPressure: 200,
      depth: 6000,
      fluidGradient: 0.3,
      frictionCoefficient: 0.0005,
    );

    test('lies on both curves', () {
      final m = NodalCalculations.buildIprFromTest(
              pr: 3000, pb: 2000, qTest: 600, pwfTest: 2400)
          .model;
      final op = NodalCalculations.findOperatingPoint(m, tpc);
      expect(op, isNotNull);
      final iprPwf = NodalCalculations.iprPwf(m, op!.flowRate);
      final tpcPwf = NodalCalculations.tubingPwf(tpc, op.flowRate);
      expect(iprPwf, closeTo(tpcPwf, 0.1));
      expect(op.bottomholePressure, closeTo(iprPwf, 0.1));
    });

    test('null when TPC starts above Pr', () {
      final m = NodalCalculations.buildIprFromPI(pr: 2000, pb: 1500, j: 1.0).model;
      const deadTpc = TpcModel(
        wellheadPressure: 500,
        depth: 8000,
        fluidGradient: 0.4,
        frictionCoefficient: 0.0005,
      );
      expect(NodalCalculations.findOperatingPoint(m, deadTpc), isNull);
    });
  });
}
