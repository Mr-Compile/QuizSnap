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

  const AnswerExplanationBottomSheet({
    super.key,
    required this.question,
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
              ),
            );
          },
        );
        return;
      }

      // Generate new explanation
      final explanation = await examProvider.generateExplanation(widget.question);

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
              ),
            );
          },
        );
        return;
      }

      // AI service unavailable or other non-network failure: show the
      // standardized "Explanation Unavailable" message instead of raw errors.
      setState(() {
        _isLoading = false;
        _errorMessage = 'unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildCorrectAnswer(),
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
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            'Answer Explanation',
            style: AppTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question',
            style: AppTheme.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            widget.question.question,
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectAnswer() {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomCard(
      color: colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Correct Answer',
                style: AppTheme.labelMedium.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            widget.question.correctAnswer ?? '',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      final colorScheme = Theme.of(context).colorScheme;
      final isUnavailable = _errorMessage == 'unavailable';
      return CustomCard(
        color: isUnavailable ? null : colorScheme.errorContainer,
        child: Column(
          children: [
            Icon(
              isUnavailable ? Icons.info_outline : Icons.error_outline,
              color: isUnavailable
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                  : colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              isUnavailable ? 'Explanation Unavailable' : 'Failed to load explanation',
              style: AppTheme.labelLarge.copyWith(
                color: isUnavailable
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : colorScheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              isUnavailable
                  ? 'No explanation is available for this question yet.'
                  : 'Please check your connection and try again.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            CustomButton(
              text: 'Retry',
              onPressed: _loadExplanation,
              isOutlined: true,
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Explanation Unavailable',
              style: AppTheme.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'No explanation is available for this question yet.',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              'AI Explanation',
              style: AppTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomCard(
          child: FormattedStudyText(
            text: sanitized,
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
            child: CustomButton(
              text: 'View Full Details',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FullExplanationScreen(
                      question: widget.question,
                      explanation: _explanation,
                    ),
                  ),
                );
              },
              icon: Icons.open_in_full,
            ),
          ),
        ],
      ),
    );
  }
}
