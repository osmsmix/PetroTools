import 'dart:math' as math;

import '../models/well_data.dart';

/// An IPR model together with the worked solution steps that produced it.
class IprResult {
  final IprModel model;
  final List<CalculationStep> steps;

  const IprResult(this.model, this.steps);
}

/// Pure functions for nodal analysis (IPR, TPC and operating point).
class NodalCalculations {
  NodalCalculations._();

  /// Vogel factor f(x) = 1 − 0.2x − 0.8x², with x = Pwf/P.
  static double vogelFactor(double x) {
    final r = x.clamp(0.0, 1.0);
    return 1 - 0.2 * r - 0.8 * r * r;
  }

  /// Inverse Vogel factor: x such that f(x) = c, taking the positive root of
  /// 0.8x² + 0.2x − c = 0.
  static double inverseVogelFactor(double c) {
    final cc = c.clamp(0.0, 1.0);
    return (-0.2 + math.sqrt(0.04 + 3.2 * cc)) / 1.6;
  }

  /// Builds the IPR when the productivity index is NOT known, from a well
  /// test point (qTest at pwfTest) and the bubble point pressure.
  static IprResult buildIprFromTest({
    required double pr,
    required double pb,
    required double qTest,
    required double pwfTest,
  }) {
    final steps = <CalculationStep>[];

    if (pr <= pb) {
      final x = pwfTest / pr;
      final f = vogelFactor(x);
      final qMax = qTest / f;
      steps.add(CalculationStep(
        title: 'Identify the reservoir regime',
        formula: 'Compare Pr with Pb',
        substitution: 'Pr = ${fmt(pr)} psi ≤ Pb = ${fmt(pb)} psi',
        result: 'Saturated reservoir → pure Vogel IPR',
      ));
      steps.add(CalculationStep(
        title: 'Vogel factor at the test point',
        formula: 'f = 1 − 0.2(Pwf,test/Pr) − 0.8(Pwf,test/Pr)²',
        substitution:
            'f = 1 − 0.2(${fmt(pwfTest)}/${fmt(pr)}) − 0.8(${fmt(pwfTest)}/${fmt(pr)})²',
        result: 'f = ${fmt(f, 4)}',
      ));
      steps.add(CalculationStep(
        title: 'Solve for qmax (AOF)',
        formula: 'qmax = q_test / f',
        substitution: 'qmax = ${fmt(qTest)} / ${fmt(f, 4)}',
        result: 'AOF = qmax = ${fmt(qMax)} STB/day',
      ));
      steps.add(const CalculationStep(
        title: 'Build the IPR curve',
        formula: 'q = qmax [1 − 0.2(Pwf/Pr) − 0.8(Pwf/Pr)²]',
        result: 'Curve plotted from Pwf = Pr down to 0',
      ));
      return IprResult(
        IprModel(
          reservoirPressure: pr,
          bubblePointPressure: pb,
          productivityIndex: null,
          qb: 0,
          qv: qMax,
        ),
        steps,
      );
    }

    steps.add(CalculationStep(
      title: 'Identify the reservoir regime',
      formula: 'Compare Pr with Pb',
      substitution: 'Pr = ${fmt(pr)} psi > Pb = ${fmt(pb)} psi',
      result: 'Undersaturated → linear IPR above Pb, Vogel below',
    ));

    final double j;
    if (pwfTest >= pb) {
      j = qTest / (pr - pwfTest);
      steps.add(CalculationStep(
        title: 'Locate the test point',
        substitution: 'Pwf,test = ${fmt(pwfTest)} psi ≥ Pb = ${fmt(pb)} psi',
        result: 'Test lies on the linear (single-phase) segment',
      ));
      steps.add(CalculationStep(
        title: 'Productivity index from the test',
        formula: 'J = q_test / (Pr − Pwf,test)',
        substitution: 'J = ${fmt(qTest)} / (${fmt(pr)} − ${fmt(pwfTest)})',
        result: 'J = ${fmt(j, 3)} STB/day/psi',
      ));
    } else {
      final f = vogelFactor(pwfTest / pb);
      final denom = (pr - pb) + (pb / 1.8) * f;
      j = qTest / denom;
      steps.add(CalculationStep(
        title: 'Locate the test point',
        substitution: 'Pwf,test = ${fmt(pwfTest)} psi < Pb = ${fmt(pb)} psi',
        result: 'Test lies on the Vogel (two-phase) segment',
      ));
      steps.add(CalculationStep(
        title: 'Productivity index from the test',
        formula: 'J = q_test / [(Pr − Pb) + (Pb/1.8)·(1 − 0.2(Pwf,test/Pb) − 0.8(Pwf,test/Pb)²)]',
        substitution:
            'J = ${fmt(qTest)} / [(${fmt(pr)} − ${fmt(pb)}) + (${fmt(pb)}/1.8)×${fmt(f, 4)}]',
        result: 'J = ${fmt(j, 3)} STB/day/psi',
      ));
    }

    return IprResult(_undersaturatedFromJ(pr, pb, j, steps), steps);
  }

  /// Builds the IPR when the productivity index IS known.
  static IprResult buildIprFromPI({
    required double pr,
    required double pb,
    required double j,
  }) {
    final steps = <CalculationStep>[];

    if (pr <= pb) {
      final qMax = j * pr / 1.8;
      steps.add(CalculationStep(
        title: 'Identify the reservoir regime',
        formula: 'Compare Pr with Pb',
        substitution: 'Pr = ${fmt(pr)} psi ≤ Pb = ${fmt(pb)} psi',
        result: 'Saturated reservoir → pure Vogel IPR',
      ));
      steps.add(CalculationStep(
        title: 'AOF from the productivity index',
        formula: 'qmax = J·Pr / 1.8',
        substitution: 'qmax = ${fmt(j, 3)} × ${fmt(pr)} / 1.8',
        result: 'AOF = qmax = ${fmt(qMax)} STB/day',
      ));
      steps.add(const CalculationStep(
        title: 'Build the IPR curve',
        formula: 'q = qmax [1 − 0.2(Pwf/Pr) − 0.8(Pwf/Pr)²]',
        result: 'Curve plotted from Pwf = Pr down to 0',
      ));
      return IprResult(
        IprModel(
          reservoirPressure: pr,
          bubblePointPressure: pb,
          productivityIndex: j,
          qb: 0,
          qv: qMax,
        ),
        steps,
      );
    }

    steps.add(CalculationStep(
      title: 'Identify the reservoir regime',
      formula: 'Compare Pr with Pb',
      substitution: 'Pr = ${fmt(pr)} psi > Pb = ${fmt(pb)} psi',
      result: 'Undersaturated → linear IPR above Pb, Vogel below',
    ));
    steps.add(CalculationStep(
      title: 'Productivity index',
      result: 'J = ${fmt(j, 3)} STB/day/psi (given)',
    ));
    return IprResult(_undersaturatedFromJ(pr, pb, j, steps), steps);
  }

  /// Shared tail of the undersaturated construction: qb, qv, qmax and curve.
  static IprModel _undersaturatedFromJ(
      double pr, double pb, double j, List<CalculationStep> steps) {
    final qb = j * (pr - pb);
    final qv = j * pb / 1.8;
    steps.add(CalculationStep(
      title: 'Rate at the bubble point',
      formula: 'qb = J (Pr − Pb)',
      substitution: 'qb = ${fmt(j, 3)} × (${fmt(pr)} − ${fmt(pb)})',
      result: 'qb = ${fmt(qb)} STB/day',
    ));
    steps.add(CalculationStep(
      title: 'Vogel segment and AOF',
      formula: 'qv = J·Pb / 1.8   →   qmax = qb + qv',
      substitution: 'qv = ${fmt(j, 3)} × ${fmt(pb)} / 1.8 = ${fmt(qv)}',
      result: 'AOF = qmax = ${fmt(qb + qv)} STB/day',
    ));
    steps.add(const CalculationStep(
      title: 'Build the IPR curve',
      formula: 'Pwf ≥ Pb:  q = J (Pr − Pwf)\n'
          'Pwf < Pb:  q = qb + qv [1 − 0.2(Pwf/Pb) − 0.8(Pwf/Pb)²]',
      result: 'Curve plotted from Pwf = Pr down to 0',
    ));
    return IprModel(
      reservoirPressure: pr,
      bubblePointPressure: pb,
      productivityIndex: j,
      qb: qb,
      qv: qv,
    );
  }

  /// Rate for a given bottomhole pressure on the composite IPR.
  static double iprFlowRate(IprModel m, double pwf) {
    if (pwf >= m.reservoirPressure) return 0;
    if (pwf >= m.pbEff) {
      return (m.productivityIndex ?? 0) * (m.reservoirPressure - pwf);
    }
    return m.qb + m.qv * vogelFactor(pwf / m.pbEff);
  }

  /// Bottomhole pressure for a given rate on the composite IPR (inverse).
  static double iprPwf(IprModel m, double q) {
    if (q <= 0) return m.reservoirPressure;
    if (q <= m.qb && m.qb > 0) {
      return m.reservoirPressure - q / m.productivityIndex!;
    }
    if (m.qv <= 0) return m.pbEff;
    final c = 1 - (q - m.qb) / m.qv;
    return m.pbEff * inverseVogelFactor(c);
  }

  /// IPR curve sampled from Pwf = Pr down to 0.
  static List<CurvePoint> iprCurve(IprModel m, {int samples = 80}) {
    return List.generate(samples + 1, (i) {
      final pwf = m.reservoirPressure * (1 - i / samples);
      return CurvePoint(iprFlowRate(m, pwf), pwf);
    });
  }

  /// Tubing performance relation: Pwf = Pwh + G·D + C·q².
  static double tubingPwf(TpcModel t, double q) {
    return t.wellheadPressure +
        t.fluidGradient * t.depth +
        t.frictionCoefficient * q * q;
  }

  /// TPC curve sampled from q = 0 to qMax.
  static List<CurvePoint> tpcCurve(TpcModel t, double qMax, {int samples = 60}) {
    return List.generate(samples + 1, (i) {
      final q = qMax * i / samples;
      return CurvePoint(q, tubingPwf(t, q));
    });
  }

  /// Finds the IPR/TPC intersection by bisection on
  /// f(q) = Pwf_IPR(q) − Pwf_TPC(q) over [0, qmax].
  ///
  /// Returns null when the curves do not intersect (the well cannot flow
  /// against the tubing back-pressure).
  static OperatingPoint? findOperatingPoint(IprModel m, TpcModel t) {
    double f(double q) => iprPwf(m, q) - tubingPwf(t, q);

    double lo = 0, hi = m.qMax;
    if (f(lo) <= 0) return null; // TPC starts above Pr: no natural flow.
    if (f(hi) > 0) return null; // Curves never cross within [0, qmax].

    for (var i = 0; i < 80; i++) {
      final mid = (lo + hi) / 2;
      if (f(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final q = (lo + hi) / 2;
    return OperatingPoint(flowRate: q, bottomholePressure: tubingPwf(t, q));
  }

  /// Compact number formatting for the step-by-step solution text.
  static String fmt(double v, [int maxDecimals = 2]) {
    var s = v.abs() >= 100
        ? v.toStringAsFixed(0)
        : v.abs() >= 1
            ? v.toStringAsFixed(maxDecimals)
            : v.toStringAsFixed(math.max(maxDecimals, 4));
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}
