import 'package:flutter/material.dart';

import '../models/well_data.dart';

/// Numbered, worked solution shown under every result.
class SolutionSteps extends StatelessWidget {
  final List<CalculationStep> steps;

  const SolutionSteps({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Solution — step by step', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++) ...[
          _StepCard(index: i + 1, step: steps[i]),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final CalculationStep step;

  const _StepCard({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.5);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (step.formula != null) ...[
                    const SizedBox(height: 6),
                    Text(step.formula!, style: mono?.copyWith(color: theme.colorScheme.primary)),
                  ],
                  if (step.substitution != null) ...[
                    const SizedBox(height: 4),
                    Text(step.substitution!,
                        style: mono?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    step.result,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF69F0AE),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
