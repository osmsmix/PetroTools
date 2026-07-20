import 'package:flutter/material.dart';

import '../models/well_data.dart';
import '../utils/nodal_calculations.dart';
import '../widgets/ipr_chart.dart';
import '../widgets/ipr_input_form.dart';
import '../widgets/solution_steps.dart';

/// Screen 1 — composite IPR (linear + Vogel) with AOF and worked steps.
class IprScreen extends StatefulWidget {
  const IprScreen({super.key});

  @override
  State<IprScreen> createState() => _IprScreenState();
}

class _IprScreenState extends State<IprScreen> {
  final _formKey = GlobalKey<FormState>();
  final _iprKey = GlobalKey<IprInputSectionState>();

  IprResult? _result;
  List<CurvePoint>? _curve;
  bool _calculating = false;

  Future<void> _calculate() async {
    if (_calculating) return;
    if (!_formKey.currentState!.validate()) return;
    final result = _iprKey.currentState!.buildIpr();
    if (result == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _calculating = true);
    // The math is instant; the short pause gives visible feedback.
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _result = result;
      _curve = NodalCalculations.iprCurve(result.model);
      _calculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = _result?.model;
    return Scaffold(
      appBar: AppBar(title: const Text('IPR Calculator')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // SingleChildScrollView (not ListView) so the input section keeps
          // its state when scrolled out of view.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FormulaCard(
                  title: 'IPR model',
                  formula:
                      'Pwf ≥ Pb:  q = J (Pr − Pwf)\n'
                      'Pwf < Pb:  q = qb + qv [1 − 0.2(Pwf/Pb) − 0.8(Pwf/Pb)²]\n'
                      'Saturated (Pr ≤ Pb): pure Vogel with Pb → Pr',
                ),
                const SizedBox(height: 20),
                IprInputSection(key: _iprKey),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _calculating ? null : _calculate,
                  icon: _calculating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: Text(_calculating ? 'Calculating…' : 'Calculate IPR'),
                ),
                if (model != null && _curve != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ValueCard(
                          label: 'AOF (qmax)',
                          value: NodalCalculations.fmt(model.qMax),
                          unit: 'STB/day',
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: model.isSaturated
                            ? const _ValueCard(
                                label: 'Regime',
                                value: 'Saturated',
                                unit: 'pure Vogel IPR',
                                color: Color(0xFF4FC3F7),
                              )
                            : _ValueCard(
                                label: 'Rate at Pb (qb)',
                                value: NodalCalculations.fmt(model.qb),
                                unit: 'STB/day',
                                color: const Color(0xFFB39DDB),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SolutionSteps(steps: _result!.steps),
                  const SizedBox(height: 14),
                  Text('IPR Curve', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                      child: IprChart(
                        iprPoints: _curve!,
                        bubblePoint: model.isSaturated
                            ? null
                            : CurvePoint(model.qb, model.bubblePointPressure),
                      ),
                    ),
                  ),
                  if (!model.isSaturated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Purple marker: bubble point (qb, Pb) — the curve is linear above it, Vogel below it.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card that shows the formula behind the result.
class _FormulaCard extends StatelessWidget {
  final String title;
  final String formula;

  const _FormulaCard({required this.title, required this.formula});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.functions,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formula,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
