import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/well_data.dart';

/// Interactive rate (x, STB/day) vs. bottomhole pressure (y, psi) chart.
///
/// Always draws the IPR curve; optionally overlays a TPC curve and the
/// operating point marker.
class IprChart extends StatelessWidget {
  final List<CurvePoint> iprPoints;
  final List<CurvePoint>? tpcPoints;
  final OperatingPoint? operatingPoint;

  /// Marks where the linear segment hands over to Vogel (qb, Pb).
  final CurvePoint? bubblePoint;

  const IprChart({
    super.key,
    required this.iprPoints,
    this.tpcPoints,
    this.operatingPoint,
    this.bubblePoint,
  });

  static const _iprColor = Color(0xFF4FC3F7);
  static const _tpcColor = Color(0xFFFFB74D);
  static const _pointColor = Color(0xFF69F0AE);
  static const _bubbleColor = Color(0xFFB39DDB);

  @override
  Widget build(BuildContext context) {
    final maxQ = iprPoints.map((p) => p.flowRate).reduce((a, b) => a > b ? a : b);
    var maxP = iprPoints.map((p) => p.pressure).reduce((a, b) => a > b ? a : b);
    if (tpcPoints != null) {
      for (final p in tpcPoints!) {
        if (p.pressure > maxP) maxP = p.pressure;
      }
    }

    final gridColor = Colors.white.withValues(alpha: 0.08);

    return AspectRatio(
      aspectRatio: 1.3,
      child: LineChart(
        LineChartData(
          minX: 0,
          minY: 0,
          maxX: maxQ * 1.05,
          maxY: maxP * 1.1,
          gridData: FlGridData(
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('Flow rate q (STB/day)'),
              axisNameSize: 24,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _niceInterval(maxQ),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_compact(value), style: const TextStyle(fontSize: 10)),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text('Pwf (psi)'),
              axisNameSize: 24,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: _niceInterval(maxP),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_compact(value), style: const TextStyle(fontSize: 10)),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF263238),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.x.toStringAsFixed(0)} STB/d\n${s.y.toStringAsFixed(0)} psi',
                        TextStyle(
                          color: s.bar.color ?? Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            _curve(iprPoints, _iprColor, fill: true),
            if (tpcPoints != null) _curve(tpcPoints!, _tpcColor),
            if (bubblePoint != null)
              LineChartBarData(
                spots: [FlSpot(bubblePoint!.flowRate, bubblePoint!.pressure)],
                color: _bubbleColor,
                dotData: FlDotData(
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFF161E27),
                    strokeWidth: 2.5,
                    strokeColor: _bubbleColor,
                  ),
                ),
              ),
            if (operatingPoint != null)
              LineChartBarData(
                spots: [
                  FlSpot(operatingPoint!.flowRate, operatingPoint!.bottomholePressure),
                ],
                color: _pointColor,
                dotData: FlDotData(
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 6,
                    color: _pointColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _curve(List<CurvePoint> points, Color color, {bool fill = false}) {
    return LineChartBarData(
      spots: [for (final p in points) FlSpot(p.flowRate, p.pressure)],
      isCurved: true,
      curveSmoothness: 0.15,
      barWidth: 3,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: fill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  static double _niceInterval(double max) {
    final raw = max / 5;
    final magnitude = raw <= 0 ? 1.0 : _pow10(raw);
    final normalized = raw / magnitude;
    final nice = normalized < 1.5
        ? 1.0
        : normalized < 3
            ? 2.0
            : normalized < 7
                ? 5.0
                : 10.0;
    return nice * magnitude;
  }

  static double _pow10(double value) {
    var m = 1.0;
    var v = value;
    while (v >= 10) {
      v /= 10;
      m *= 10;
    }
    while (v < 1) {
      v *= 10;
      m /= 10;
    }
    return m;
  }

  static String _compact(double value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) {
      final k = value / 1000;
      return k == k.roundToDouble() ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
