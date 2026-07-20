import 'dart:math' as math;

/// Composite IPR model.
///
/// Undersaturated (Pr > Pb): linear q = J(Pr − Pwf) above Pb, Vogel below.
/// Saturated (Pr ≤ Pb): pure Vogel over the whole range (qb = 0).
class IprModel {
  /// Reservoir pressure Pr (psi).
  final double reservoirPressure;

  /// Bubble point pressure Pb (psi), as entered.
  final double bubblePointPressure;

  /// Productivity index J (STB/day/psi). Null when the IPR was built from a
  /// test in a saturated reservoir, where J is not needed.
  final double? productivityIndex;

  /// Rate at the bubble point (STB/day). 0 for saturated reservoirs.
  final double qb;

  /// Size of the Vogel segment, qv = qmax − qb (STB/day).
  final double qv;

  const IprModel({
    required this.reservoirPressure,
    required this.bubblePointPressure,
    required this.productivityIndex,
    required this.qb,
    required this.qv,
  });

  bool get isSaturated => reservoirPressure <= bubblePointPressure;

  /// Pressure where the Vogel segment starts (Pb capped at Pr).
  double get pbEff => math.min(bubblePointPressure, reservoirPressure);

  /// Absolute open flow: rate at Pwf = 0.
  double get qMax => qb + qv;
}

/// Tubing performance curve inputs: Pwf = Pwh + G·D + C·q².
class TpcModel {
  /// Wellhead pressure Pwh (psi).
  final double wellheadPressure;

  /// True vertical depth D (ft).
  final double depth;

  /// Average flowing fluid gradient G (psi/ft).
  final double fluidGradient;

  /// Friction coefficient C (psi/(STB/day)²).
  final double frictionCoefficient;

  const TpcModel({
    required this.wellheadPressure,
    required this.depth,
    required this.fluidGradient,
    required this.frictionCoefficient,
  });
}

/// A single point on a rate vs. pressure curve.
class CurvePoint {
  final double flowRate; // STB/day
  final double pressure; // psi

  const CurvePoint(this.flowRate, this.pressure);
}

/// Intersection of the IPR and TPC curves.
class OperatingPoint {
  final double flowRate; // STB/day
  final double bottomholePressure; // psi

  const OperatingPoint({
    required this.flowRate,
    required this.bottomholePressure,
  });
}

/// One step of a worked solution, shown to the student.
class CalculationStep {
  final String title;
  final String? formula;
  final String? substitution;
  final String result;

  const CalculationStep({
    required this.title,
    this.formula,
    this.substitution,
    required this.result,
  });
}
