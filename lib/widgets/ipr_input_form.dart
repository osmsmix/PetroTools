import 'package:flutter/material.dart';

import '../utils/nodal_calculations.dart';
import 'input_field.dart';

enum IprInputMode { testData, productivityIndex }

/// Reservoir inputs shared by the IPR and operating point screens.
///
/// Lets the student choose between entering a well test point (when PI is
/// unknown) or the productivity index directly. Must be placed inside a
/// [Form]; call [buildIpr] after the form validates.
class IprInputSection extends StatefulWidget {
  const IprInputSection({super.key});

  @override
  State<IprInputSection> createState() => IprInputSectionState();
}

class IprInputSectionState extends State<IprInputSection> {
  final _prController = TextEditingController(text: '3000');
  final _pbController = TextEditingController(text: '2000');
  final _qTestController = TextEditingController(text: '600');
  final _pwfTestController = TextEditingController(text: '2400');
  final _jController = TextEditingController(text: '1.0');
  IprInputMode _mode = IprInputMode.testData;

  @override
  void dispose() {
    _prController.dispose();
    _pbController.dispose();
    _qTestController.dispose();
    _pwfTestController.dispose();
    _jController.dispose();
    super.dispose();
  }

  /// Parses the fields and builds the IPR with its solution steps.
  /// Returns null (with a snackbar) when values are physically inconsistent.
  IprResult? buildIpr() {
    final pr = double.parse(_prController.text);
    final pb = double.parse(_pbController.text);
    if (pr <= 0) {
      _complain('Reservoir pressure must be greater than zero');
      return null;
    }
    if (_mode == IprInputMode.productivityIndex) {
      final j = double.parse(_jController.text);
      if (j <= 0) {
        _complain('Productivity index must be greater than zero');
        return null;
      }
      return NodalCalculations.buildIprFromPI(pr: pr, pb: pb, j: j);
    }
    final qTest = double.parse(_qTestController.text);
    final pwfTest = double.parse(_pwfTestController.text);
    if (qTest <= 0) {
      _complain('Test flow rate must be greater than zero');
      return null;
    }
    if (pwfTest >= pr) {
      _complain('Test Pwf must be below the reservoir pressure');
      return null;
    }
    return NodalCalculations.buildIprFromTest(
        pr: pr, pb: pb, qTest: qTest, pwfTest: pwfTest);
  }

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reservoir inflow (IPR)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        AppInputField(
          label: 'Reservoir Pressure (Pr)',
          unit: 'psi',
          controller: _prController,
        ),
        const SizedBox(height: 16),
        AppInputField(
          label: 'Bubble Point Pressure (Pb)',
          unit: 'psi',
          controller: _pbController,
          helperText: 'Pr ≤ Pb → saturated (pure Vogel)',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<IprInputMode>(
            segments: const [
              ButtonSegment(
                value: IprInputMode.testData,
                label: Text('No PI — use well test'),
                icon: Icon(Icons.science_outlined),
              ),
              ButtonSegment(
                value: IprInputMode.productivityIndex,
                label: Text('PI known'),
                icon: Icon(Icons.speed),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_mode == IprInputMode.testData) ...[
          AppInputField(
            label: 'Test Flow Rate (q test)',
            unit: 'STB/day',
            controller: _qTestController,
          ),
          const SizedBox(height: 16),
          AppInputField(
            label: 'Test Bottomhole Pressure (Pwf test)',
            unit: 'psi',
            controller: _pwfTestController,
            helperText: 'Measured together with q test',
          ),
        ] else
          AppInputField(
            label: 'Productivity Index (J)',
            unit: 'STB/day/psi',
            controller: _jController,
          ),
      ],
    );
  }
}
