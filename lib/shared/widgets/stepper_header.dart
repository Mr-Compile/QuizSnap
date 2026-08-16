import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

const List<String> kAiWizardSteps = ['Source', 'Content', 'Configure', 'Generate', 'Review'];

/// A compact horizontal stepper for the document-analysis flow.
class StepperHeader extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepperHeader({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _buildStep(context, i, colorScheme),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentStep
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int index, ColorScheme colorScheme) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;
    final color = isCompleted
        ? colorScheme.primary
        : isActive
            ? colorScheme.primary
            : colorScheme.outline;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted || isActive ? color : colorScheme.surface,
          child: isCompleted
              ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? colorScheme.onPrimary : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          steps[index],
          style: AppTheme.bodySmall.copyWith(
            color: isActive ? colorScheme.primary : color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
