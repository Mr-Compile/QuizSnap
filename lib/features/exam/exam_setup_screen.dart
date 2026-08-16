import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import 'countdown_screen.dart';
import '../../core/services/dialog_service.dart';

class ExamSetupScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const ExamSetupScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  int _selectedQuestionCount = 10;
  int _selectedTimeLimit = 10; // in minutes
  bool _isLoading = true;
  bool _isCustomTime = false;
  bool _shuffle = false;
  String? _timeError;
  int _availableCardCount = 0;

  final _customTimeController = TextEditingController();

  final List<int> _baseQuestionCountOptions = [5, 10, 15, 20, 25, 30, 50, 100];
  List<int> _questionCountOptions = [];
  static const int _maxQuestionCount = 100;
  final List<int> _timeLimitPresets = [1, 5, 10, 15, 20, 25, 30];
  static const int _minTimeLimit = 1;
  static const int _maxTimeLimit = 120;

  @override
  void initState() {
    super.initState();
    _customTimeController.text = '$_selectedTimeLimit';
    _checkDeckCardCount();
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  Future<void> _checkDeckCardCount() async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      final flashcards = await dbProvider.flashcardRepository
          .getFlashcardsByDeck(widget.deckId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _availableCardCount = flashcards.length;
          _questionCountOptions = _buildQuestionCountOptions(_availableCardCount);

          final effectiveMax = min(_availableCardCount, _maxQuestionCount);
          if (_availableCardCount == 0) {
            _selectedQuestionCount = 0;
          } else {
            final target = min(10, effectiveMax);
            _selectedQuestionCount = _questionCountOptions.lastWhere(
              (count) => count <= target,
              orElse: () => _questionCountOptions.first,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _availableCardCount = 0;
          _questionCountOptions = _buildQuestionCountOptions(0);
          _selectedQuestionCount = 0;
        });
      }
    }
  }

  List<int> _buildQuestionCountOptions(int availableCount) {
    final effectiveMax = min(availableCount, _maxQuestionCount);
    final options = List<int>.from(_baseQuestionCountOptions);

    if (effectiveMax > 0 && !options.contains(effectiveMax)) {
      options.add(effectiveMax);
      options.sort();
    }

    return options;
  }

  Future<void> _startExam() async {
    if (!_validateTime()) {
      await DialogService.showError(
        context,
        _timeError ?? 'Enter a valid time between $_minTimeLimit and $_maxTimeLimit minutes.',
      );
      return;
    }

    if (_availableCardCount == 0) {
      await DialogService.showError(
        context,
        'This deck has no flashcards. Add cards before starting an exam.',
      );
      return;
    }

    if (_selectedQuestionCount > _availableCardCount) {
      await DialogService.showError(
        context,
        'This deck only has $_availableCardCount cards available.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final examProvider = context.read<ExamProvider>();

      await examProvider.createExam(
        deckId: widget.deckId,
        deckName: widget.deckName,
        questionCount: _selectedQuestionCount,
        timeLimit: _selectedTimeLimit,
      );

      await examProvider.generateQuestions(shuffle: _shuffle);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CountdownScreen(
              examId: examProvider.currentExam!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error starting exam: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateTime() {
    if (_selectedTimeLimit < _minTimeLimit || _selectedTimeLimit > _maxTimeLimit) {
      setState(() {
        _timeError = 'Time must be between $_minTimeLimit and $_maxTimeLimit minutes.';
      });
      return false;
    }
    setState(() => _timeError = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exam Setup',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeckInfo(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildQuestionCountSelector(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildTimeLimitSelector(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildShuffleToggle(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildSummary(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildStartButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeckInfo() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exam Deck',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Icon(
                Icons.style,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  widget.deckName,
                  style: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Number of Questions',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '$_selectedQuestionCount questions',
            style: AppTheme.bodyMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Available: $_availableCardCount cards',
            style: AppTheme.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: _questionCountOptions.map((count) {
              final isSelected = count == _selectedQuestionCount;
              final isDisabled = count > _availableCardCount;

              return FilterChip(
                label: Text(
                  '$count',
                  style: TextStyle(
                    color: isDisabled
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : null,
                  ),
                ),
                selected: isSelected,
                onSelected: isDisabled
                    ? null
                    : (selected) {
                        setState(() => _selectedQuestionCount = count);
                      },
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: colorScheme.primary,
                disabledColor: colorScheme.surfaceContainerHighest,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitSelector() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Limit',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _formatTime(_selectedTimeLimit),
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: _timeLimitPresets.map((minutes) {
              final isSelected = minutes == _selectedTimeLimit && !_isCustomTime;
              return FilterChip(
                label: Text(_formatTime(minutes)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTimeLimit = minutes;
                    _isCustomTime = false;
                    _customTimeController.text = '$minutes';
                    _timeError = null;
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _customTimeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom time (minutes)',
              errorText: _isCustomTime ? _timeError : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              setState(() {
                _isCustomTime = true;
                if (parsed != null) {
                  _selectedTimeLimit = parsed;
                  _timeError = (parsed < _minTimeLimit || parsed > _maxTimeLimit)
                      ? 'Time must be between $_minTimeLimit and $_maxTimeLimit minutes.'
                      : null;
                } else {
                  _timeError = 'Enter a number.';
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShuffleToggle() {
    return CustomCard(
      child: SwitchListTile(
        title: Text(
          'Shuffle questions',
          style: AppTheme.labelLarge,
        ),
        subtitle: Text(
          'Randomize the order of questions for this exam',
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        value: _shuffle,
        onChanged: (value) => setState(() => _shuffle = value),
        secondary: Icon(
          Icons.shuffle,
          color: Theme.of(context).colorScheme.primary,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSummary() {
    return CustomCard(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Exam Summary',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildSummaryRow('Deck', widget.deckName),
          _buildSummaryRow('Questions', '$_selectedQuestionCount'),
          _buildSummaryRow('Time Limit', _formatTime(_selectedTimeLimit)),
          _buildSummaryRow('Shuffle', _shuffle ? 'On' : 'Off'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return CustomButton(
      text: 'Start Exam',
      onPressed: _startExam,
      icon: Icons.play_arrow,
      fullWidth: true,
      isLoading: _isLoading,
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }
}
