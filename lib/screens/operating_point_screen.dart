import 'package:flutter/material.dart';

import '../models/well_data.dart';
import '../utils/nodal_calculations.dart';
import '../widgets/input_field.dart';
import '../widgets/ipr_chart.dart';
import '../widgets/ipr_input_form.dart';
import '../widgets/solution_steps.dart';

/// Screen 2 — intersection of the IPR and TPC curves (the operating point).
class OperatingPointScreen extends StatefulWidget {
  const OperatingPointScreen({super.key});

  @override
  State<OperatingPointScreen> createState() => _OperatingPointScreenState();
}

class _OperatingPointScreenState extends State<OperatingPointScreen> {
  final _formKey = GlobalKey<FormState>();
  final _iprKey = GlobalKey<IprInputSectionState>();
  final _pwhController = TextEditingController(text: '200');
  final _depthController = TextEditingController(text: '6000');
  final _gradientController = TextEditingController(text: '0.3');
  final _frictionController = TextEditingController(text: '0.0005');

  IprModel? _model;
  List<CalculationStep>? _steps;
  List<CurvePoint>? _ipr;
  List<CurvePoint>? _tpc;
  OperatingPoint? _operatingPoint;
  bool _noIntersection = false;

  @override
  void dispose() {
    _pwhController.dispose();
    _depthController.dispose();
    _gradientController.dispose();
    _frictionController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final iprResult = _iprKey.currentState!.buildIpr();
    if (iprResult == null) return;
    final model = iprResult.model;
    final tpc = TpcModel(
      wellheadPressure: double.parse(_pwhController.text),
      depth: double.parse(_depthController.text),
      fluidGradient: double.parse(_gradientController.text),
      frictionCoefficient: double.parse(_frictionController.text),
    );
    final op = NodalCalculations.findOperatingPoint(model, tpc);

    final intercept = tpc.wellheadPressure + tpc.fluidGradient * tpc.depth;
    final fmt = NodalCalculations.fmt;
    final steps = [
      ...iprResult.steps,
      CalculationStep(
        title: 'Tubing performance curve',
        formula: 'Pwf = Pwh + G·D + C·q²',
        substitution:
            'Pwf = ${fmt(tpc.wellheadPressure)} + ${fmt(tpc.fluidGradient)}×${fmt(tpc.depth)} + ${fmt(tpc.frictionCoefficient, 6)}·q²',
        result: 'TPC intercept at q = 0: ${fmt(intercept)} psi',
      ),
      op == null
          ? CalculationStep(
              title: 'Find the intersection',
              formula: 'Pwf,IPR(q) = Pwf,TPC(q)',
              substitution:
                  'The TPC (starting at ${fmt(intercept)} psi) stays above the IPR everywhere',
              result: 'No intersection — the well cannot flow naturally',
            )
          : CalculationStep(
              title: 'Find the intersection (operating point)',
              formula: 'Pwf,IPR(q) = Pwf,TPC(q)',
              substitution: 'Solved numerically (bisection) on 0 ≤ q ≤ qmax',
              result:
                  'q = ${fmt(op.flowRate)} STB/day,  Pwf = ${fmt(op.bottomholePressure)} psi',
            ),
    ];

    setState(() {
      _model = model;
      _steps = steps;
      _ipr = NodalCalculations.iprCurve(model);
      _tpc = NodalCalculations.tpcCurve(tpc, model.qMax);
      _operatingPoint = op;
      _noIntersection = op == null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Operating Point')),
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
                Card(
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
                              'Model',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'IPR:  linear above Pb, Vogel below (composite)\n'
                          'TPC:  Pwf = Pwh + G·D + C·q²',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Operating point = intersection of IPR and TPC',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                IprInputSection(key: _iprKey),
                const SizedBox(height: 20),
                Text('Tubing (TPC)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                AppInputField(
                  label: 'Wellhead Pressure (Pwh)',
                  unit: 'psi',
                  controller: _pwhController,
                ),
                const SizedBox(height: 16),
                AppInputField(
                  label: 'Well Depth (D)',
                  unit: 'ft',
                  controller: _depthController,
                ),
                const SizedBox(height: 16),
                AppInputField(
                  label: 'Fluid Gradient (G)',
                  unit: 'psi/ft',
                  controller: _gradientController,
                  helperText: 'Typical: 0.3–0.45 psi/ft',
                ),
                const SizedBox(height: 16),
                AppInputField(
                  label: 'Friction Coefficient (C)',
                  unit: 'psi/(STB/d)²',
                  controller: _frictionController,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Find Operating Point'),
                ),
                if (_noIntersection) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.4,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No operating point found: the TPC lies above the IPR, '
                        'so the well cannot flow naturally under these conditions. '
                        'Try a lower wellhead pressure, depth or gradient.',
                      ),
                    ),
                  ),
                ],
                if (_operatingPoint != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ValueCard(
                          label: 'Flow Rate',
                          value: NodalCalculations.fmt(
                            _operatingPoint!.flowRate,
                          ),
                          unit: 'STB/day',
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ValueCard(
                          label: 'Bottomhole Pressure',
                          value: NodalCalculations.fmt(
                            _operatingPoint!.bottomholePressure,
                          ),
                          unit: 'psi',
                          color: const Color(0xFF4FC3F7),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_steps != null) ...[
                  const SizedBox(height: 24),
                  SolutionSteps(steps: _steps!),
                ],
                if (_ipr != null && _tpc != null) ...[
                  const SizedBox(height: 14),
                  Text('IPR vs TPC', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Legend(showBubblePoint: !(_model?.isSaturated ?? true)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                      child: IprChart(
                        iprPoints: _ipr!,
                        tpcPoints: _tpc!,
                        operatingPoint: _operatingPoint,
                        bubblePoint: (_model != null && !_model!.isSaturated)
                            ? CurvePoint(
                                _model!.qb,
                                _model!.bubblePointPressure,
                              )
                            : null,
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

class _Legend extends StatelessWidget {
  final bool showBubblePoint;

  const _Legend({required this.showBubblePoint});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        const _LegendItem(color: Color(0xFF4FC3F7), label: 'IPR'),
        const _LegendItem(color: Color(0xFFFFB74D), label: 'TPC'),
        const _LegendItem(color: Color(0xFF69F0AE), label: 'Operating point'),
        if (showBubblePoint)
          const _LegendItem(color: Color(0xFFB39DDB), label: 'Bubble point'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
