import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'countdown_screen.dart';

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
  int _selectedTimeLimit = 30; // in minutes
  bool _useAI = false;
  bool _isLoading = false;

  final List<int> _questionCountOptions = [5, 10, 15, 20, 25, 30, 50, 100];
  final List<int> _timeLimitOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _checkDeckCardCount();
  }

  Future<void> _checkDeckCardCount() async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      final flashcards = await dbProvider.flashcardRepository
          .getFlashcardsByDeck(widget.deckId);
      
      if (mounted) {
        setState(() {
          // Adjust default question count if deck has fewer cards
          if (flashcards.length < _selectedQuestionCount) {
            _selectedQuestionCount = flashcards.length;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _startExam() async {
    setState(() => _isLoading = true);

    try {
      final examProvider = context.read<ExamProvider>();
      final groqProvider = context.read<GroqProvider>();

      // Check if AI is available if requested
      if (_useAI && !groqProvider.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI service not available. Using basic questions.')),
          );
          setState(() {
            _useAI = false;
          });
        }
      }

      // Create exam
      await examProvider.createExam(
        deckId: widget.deckId,
        deckName: widget.deckName,
        questionCount: _selectedQuestionCount,
        timeLimit: _selectedTimeLimit,
      );

      // Generate questions
      await examProvider.generateQuestions(useAI: _useAI);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting exam: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  _buildAIOptions(),
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
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: _questionCountOptions.map((count) {
              final isSelected = count == _selectedQuestionCount;
              return FilterChip(
                label: Text('$count'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedQuestionCount = count);
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
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
            children: _timeLimitOptions.map((minutes) {
              final isSelected = minutes == _selectedTimeLimit;
              return FilterChip(
                label: Text(_formatTime(minutes)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedTimeLimit = minutes);
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIOptions() {
    final groqProvider = context.watch<GroqProvider>();
    final isAIAvailable = groqProvider.isInitialized;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Questions',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SwitchListTile(
            title: const Text('Generate questions with AI'),
            subtitle: Text(
              isAIAvailable
                  ? 'AI will create varied questions from your flashcards'
                  : 'AI service not configured',
            ),
            value: _useAI && isAIAvailable,
            onChanged: isAIAvailable
                ? (value) {
                    setState(() => _useAI = value);
                  }
                : null,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return CustomCard(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
          _buildSummaryRow('Question Type', _useAI ? 'AI Generated' : 'Basic'),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
