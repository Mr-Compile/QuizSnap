import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/exam.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/services/connectivity_guard.dart';
import '../../core/services/dialog_service.dart';
import '../../core/utils/explanation_sanitizer.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/formatted_study_text.dart';
import 'full_explanation_screen.dart';

class AnswerExplanationBottomSheet extends StatefulWidget {
  final ExamQuestion question;
  final UserAnswer? userAnswer;

  const AnswerExplanationBottomSheet({
    super.key,
    required this.question,
    this.userAnswer,
  });

  @override
  State<AnswerExplanationBottomSheet> createState() => _AnswerExplanationBottomSheetState();
}

class _AnswerExplanationBottomSheetState extends State<AnswerExplanationBottomSheet> {
  bool _isLoading = false;
  String? _explanation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  Future<void> _loadExplanation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examProvider = context.read<ExamProvider>();

      // AI explanation requires connectivity - guard before the request.
      final online = await ConnectivityGuard.isOnline();
      if (!mounted) return;
      if (!online) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        // Close the bottom sheet first, then show the dialog from the parent
        // context so it is centered properly.
        Navigator.of(context).pop();
        await DialogService.showNoInternet(
          context,
          onRetry: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AnswerExplanationBottomSheet(
                question: widget.question,
                userAnswer: widget.userAnswer,
              ),
            );
          },
        );
        return;
      }

      // Generate new explanation
      final explanation = await examProvider.generateExplanation(
        widget.question,
        userAnswer: widget.userAnswer,
      );

      if (!mounted) return;
      setState(() {
        _explanation = explanation;
        _isLoading = false;
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      final isNetworkError = message.contains('socket') ||
          message.contains('network') ||
          message.contains('connection') ||
          message.contains('host') ||
          message.contains('failed host lookup') ||
          message.contains('internet');

      if (isNetworkError) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        Navigator.of(context).pop();
        if (!mounted) return;
        await DialogService.showNoInternet(
          context,
          onRetry: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AnswerExplanationBottomSheet(
                question: widget.question,
                userAnswer: widget.userAnswer,
              ),
            );
          },
        );
        return;
      }

      // AI service unavailable or other non-network failure: show the
      // standardized "Explanation Unavailable" message instead of raw errors.
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                0,
                AppTheme.spacingLg,
                AppTheme.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildAnswerComparison(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildExplanation(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingSm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingXs,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: colorScheme.primary,
            semanticLabel: 'Answer explanation',
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Answer Explanation',
              style: AppTheme.titleLarge.copyWith(color: colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question',
            style: AppTheme.labelMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            widget.question.question,
            style: AppTheme.bodyLarge.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  String _getUserAnswerText() {
    final answer = widget.userAnswer;
    if (answer == null) return 'No answer';

    final selectedIndex = answer.selectedAnswerIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < widget.question.options.length) {
      return widget.question.options[selectedIndex];
    }

    if (answer.textAnswer != null && answer.textAnswer!.trim().isNotEmpty) {
      return answer.textAnswer!.trim();
    }

    if (answer.listAnswer != null && answer.listAnswer!.isNotEmpty) {
      return answer.listAnswer!.join(', ');
    }

    return 'No answer';
  }

  bool get _hasUserAnswer {
    final answer = widget.userAnswer;
    return answer != null && answer.hasAnswer;
  }

  Widget _buildAnswerComparison() {
    final colorScheme = Theme.of(context).colorScheme;
    final userAnswerText = _getUserAnswerText();
    final correctAnswerText = widget.question.correctAnswerText.trim();

    // Do not render an empty answer container.
    if (correctAnswerText.isEmpty) {
      return const SizedBox.shrink();
    }

    final isUserCorrect = _hasUserAnswer && (widget.userAnswer?.isCorrect ?? false);
    final userColor = _hasUserAnswer
        ? (isUserCorrect ? colorScheme.primary : colorScheme.error)
        : colorScheme.onSurface;
    final userIcon = _hasUserAnswer
        ? (isUserCorrect ? Icons.check_circle : Icons.cancel)
        : Icons.help;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnswerRow(
            context,
            label: 'Your answer',
            value: userAnswerText,
            color: userColor,
            icon: userIcon,
          ),
          Divider(
            color: colorScheme.outline.withValues(alpha: 0.2),
            height: AppTheme.spacingLg,
          ),
          _buildAnswerRow(
            context,
            label: 'Correct answer',
            value: correctAnswerText,
            color: colorScheme.primary,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              label,
              style: AppTheme.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanation() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Generating explanation...',
                style: AppTheme.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      final isUnavailable = _errorMessage == 'unavailable';
      return CustomCard(
        color: isUnavailable ? null : colorScheme.errorContainer,
        child: Column(
          children: [
            Icon(
              isUnavailable ? Icons.info_outline : Icons.error_outline,
              color: isUnavailable
                  ? colorScheme.onSurface.withValues(alpha: 0.4)
                  : colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              isUnavailable ? 'Explanation Unavailable' : 'Failed to load explanation',
              style: AppTheme.labelLarge.copyWith(
                color: isUnavailable
                    ? colorScheme.onSurface.withValues(alpha: 0.6)
                    : colorScheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              isUnavailable
                  ? 'We couldn\'t generate an explanation right now. Please check your internet connection or AI configuration and try again.'
                  : 'Please check your connection and try again.',
              style: AppTheme.bodyMedium.copyWith(
                color: isUnavailable
                    ? colorScheme.onSurface.withValues(alpha: 0.6)
                    : colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sanitized = _explanation != null && _explanation!.isNotEmpty
        ? ExplanationSanitizer.sanitize(_explanation)
        : '';

    if (sanitized.isEmpty) {
      return CustomCard(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Explanation Unavailable',
              style: AppTheme.labelLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'No explanation is available for this question yet.',
              style: AppTheme.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'AI explanation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'AI Explanation',
                style: AppTheme.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          CustomCard(
            child: FormattedStudyText(
              text: sanitized,
              style: AppTheme.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = _errorMessage != null;
    final hasExplanation = _explanation != null && _explanation!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: hasError
                ? CustomButton(
                    text: 'Retry',
                    onPressed: _loadExplanation,
                  )
                : hasExplanation
                    ? CustomButton(
                        text: 'View Full Details',
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FullExplanationScreen(
                                question: widget.question,
                                explanation: _explanation,
                                userAnswer: widget.userAnswer,
                              ),
                            ),
                          );
                        },
                        icon: Icons.open_in_full,
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
