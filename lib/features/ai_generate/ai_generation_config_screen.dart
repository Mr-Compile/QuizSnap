import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/prompt_template.dart';
import '../../core/models/recent_generation.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/connectivity_guard.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/content_capacity_service.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../core/services/question_generation_service.dart';
import '../../core/services/text_normalization_service.dart';
import '../../core/navigation/app_routes.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/stepper_header.dart';
import 'question_review_screen.dart';

class AiGenerationConfigScreen extends StatefulWidget {
  final String sourceText;
  final String source;
  final int? sourcePage;
  final String? sourceSection;

  const AiGenerationConfigScreen({
    super.key,
    required this.sourceText,
    required this.source,
    this.sourcePage,
    this.sourceSection,
  });

  @override
  State<AiGenerationConfigScreen> createState() => _AiGenerationConfigScreenState();
}

class _AiGenerationConfigScreenState extends State<AiGenerationConfigScreen> {
  PromptType _selectedType = PromptType.multipleChoice;
  Difficulty _selectedDifficulty = Difficulty.medium;
  QuestionStyle _selectedStyle = QuestionStyle.distractors;
  int _questionCount = 10;
  bool _isGenerating = false;
  String _generationStep = '';
  double _generationProgress = 0.0;
  CapacityResult? _capacityResult;
  bool _hasActiveFolder = false;
  bool _hasActiveDeck = false;
  int? _firstFolderId;

  @override
  void initState() {
    super.initState();
    _recalculateCapacity();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrerequisites());
  }

  void _recalculateCapacity() {
    _capacityResult = ContentCapacityService.estimate(
      widget.sourceText,
      _selectedType,
      _questionCount,
    );
  }

  Future<void> _checkPrerequisites() async {
    if (!mounted) return;
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

    try {
      final folders = await dbProvider.folderRepository.getAllFolders();
      final decks = await dbProvider.deckRepository.getAllDecks();

      if (!mounted) return;
      setState(() {
        _hasActiveFolder = folders.isNotEmpty;
        _hasActiveDeck = decks.isNotEmpty;
        _firstFolderId = folders.isNotEmpty ? folders.first.id : null;
      });

      if (folders.isEmpty) {
        await _showNoFolderDialog();
      } else if (decks.isEmpty) {
        await _showNoDeckDialog();
      }
    } catch (e) {
      debugPrint('Prerequisite check error: $e');
    }
  }

  Future<void> _showNoFolderDialog() async {
    if (!mounted) return;
    await DialogService.showError(
      context,
      'Your generated flashcards need a folder and deck before they can be saved.',
      title: 'Create a folder first',
      primaryAction: 'Create Folder',
      onPrimaryAction: () => context.push(AppRoutes.createFolder),
      secondaryAction: 'Learn How It Works',
      onSecondaryAction: () => context.push(AppRoutes.userManual),
    );
  }

  Future<void> _showNoDeckDialog() async {
    if (!mounted) return;
    final route = _firstFolderId != null
        ? '${AppRoutes.createDeck}?folderId=$_firstFolderId'
        : AppRoutes.createDeck;
    await DialogService.showError(
      context,
      'Choose or create a deck where your generated flashcards will be saved.',
      title: 'Create a deck first',
      primaryAction: 'Create Deck',
      onPrimaryAction: () => context.push(route),
      secondaryAction: 'Close',
      onSecondaryAction: () {},
    );
  }

  Future<void> _showCapacityDialog(CapacityResult result) async {
    if (!mounted) return;
    await DialogService.showError(
      context,
      result.reason,
      title: 'Not enough content',
      primaryAction: 'OK',
      onPrimaryAction: () {},
      secondaryAction: 'Close',
      onSecondaryAction: () {},
    );
  }

  bool get _canGenerate {
    return _capacityResult?.isValid == true && _hasActiveFolder && _hasActiveDeck;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Configure Generation',
      ),
      body: Column(
        children: [
          StepperHeader(
            currentStep: _isGenerating ? 3 : 2,
            steps: kAiWizardSteps,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Source info
                _buildSourceInfo(),
          const SizedBox(height: 24),
          
          // Question type selection
          _buildSectionTitle('Question Type'),
          const SizedBox(height: 12),
          _buildQuestionTypeSelector(),
          const SizedBox(height: 24),

          // Question style (only for Multiple Choice and Mixed Format)
          if (_selectedType == PromptType.multipleChoice ||
              _selectedType == PromptType.mixedFormat) ...[
            _buildSectionTitle('Question Style'),
            const SizedBox(height: 12),
            _buildQuestionStyleSelector(),
            const SizedBox(height: 24),
          ],

          // Difficulty selection
          _buildSectionTitle('Difficulty'),
          const SizedBox(height: 12),
          _buildDifficultySelector(),
          const SizedBox(height: 24),
          
          // Question count
          _buildSectionTitle('Number of Questions'),
          const SizedBox(height: 12),
          _buildQuestionCountSelector(),
          const SizedBox(height: 24),
          
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating || !_canGenerate ? null : _startGeneration,
              child: _isGenerating
                  ? _buildGeneratingButton()
                  : const Text('Generate Questions'),
            ),
          ),
          
          // Progress indicator
          if (_isGenerating)
            _buildProgressIndicator(),
        ],
      ),
    ),
  ],
),
);
  }

  Widget _buildSourceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source: ${widget.source}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Text length: ${widget.sourceText.length} characters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildQuestionTypeSelector() {
    return Column(
      children: PromptType.values.map((type) {
        final isSelected = _selectedType == type;
        return RadioListTile<PromptType>(
          title: Row(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(type.displayName),
            ],
          ),
          subtitle: Text(_getTypeDescription(type)),
          value: type,
          // ignore: deprecated_member_use
          groupValue: _selectedType,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
                _recalculateCapacity();
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  String _getTypeDescription(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return 'Questions with 4 answer options. Choose With Distractors or Situational below.';
      case PromptType.identification:
        return 'Direct answer questions';
      case PromptType.enumeration:
        return 'List-based questions';
      case PromptType.mixedFormat:
        return 'Multiple formats in one request (multiple choice, identification, enumeration). Choose With Distractors or Situational below.';
    }
  }

  Widget _buildQuestionStyleSelector() {
    return Column(
      children: QuestionStyle.values.map((style) {
        final isSelected = _selectedStyle == style;
        return RadioListTile<QuestionStyle>(
          title: Text(style.displayName),
          subtitle: Text(style.description),
          value: style,
          // ignore: deprecated_member_use
          groupValue: _selectedStyle,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStyle = value;
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: Difficulty.values.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        return RadioListTile<Difficulty>(
          title: Text(difficulty.displayName),
          subtitle: Text(difficulty.description),
          value: difficulty,
          // ignore: deprecated_member_use
          groupValue: _selectedDifficulty,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDifficulty = value;
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCountSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverCapacity = !(_capacityResult?.isValid ?? true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 50,
          divisions: 9,
          label: _questionCount.toString(),
          onChanged: (value) {
            setState(() {
              _questionCount = value.round();
              _recalculateCapacity();
            });
          },
        ),
        Center(
          child: Text(
            '$_questionCount questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isOverCapacity ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ),
        if (_capacityResult != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Estimated capacity: ${_capacityResult!.estimatedCapacity} questions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isOverCapacity ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isOverCapacity) ...[
            const SizedBox(height: 8),
            Text(
              _capacityResult!.reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ] else ...[
          Text(
            'More questions may take longer to generate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startGeneration() async {
    _recalculateCapacity();
    final capacity = _capacityResult;
    if (capacity != null && !capacity.isValid) {
      if (mounted) await _showCapacityDialog(capacity);
      return;
    }

    if (!_hasActiveFolder) {
      if (mounted) await _showNoFolderDialog();
      return;
    }

    if (!_hasActiveDeck) {
      if (mounted) await _showNoDeckDialog();
      return;
    }

    final groqProvider = Provider.of<GroqProvider>(context, listen: false);
    final quotaProvider = Provider.of<AiQuotaProvider>(context, listen: false);

    if (!groqProvider.isInitialized) {
      if (mounted) {
        await DialogService.showInfo(context, 'Please configure your Groq API key first');
      }
      return;
    }

    // Check quota
    if (!quotaProvider.canRequest) {
      if (mounted) {
        await _showQuotaExceededDialog();
      }
      return;
    }

    // Connectivity guard - block AI requests when offline
    if (!mounted) return;
    final connected = await ConnectivityGuard.run(
      context,
      () async => await _performGeneration(groqProvider, quotaProvider),
    );
    if (!connected) return;
  }

  Future<void> _performGeneration(
    GroqProvider groqProvider,
    AiQuotaProvider quotaProvider,
  ) async {
    setState(() {
      _isGenerating = true;
      _generationStep = 'Preparing...';
      _generationProgress = 0.0;
    });

    try {
      // Step 1: Preparing
      await _updateGenerationProgress('Preparing text for analysis...', 0.1);

      // Step 2: Processing
      await _updateGenerationProgress('Processing document content...', 0.2);

      final generationService = QuestionGenerationService(groqProvider.service);

      // Step 3: Generating
      await _updateGenerationProgress('Generating questions with AI...', 0.5);

      final questions = await generationService.generateQuestions(
        sourceText: widget.sourceText,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        questionCount: _questionCount,
        style: _selectedStyle,
        model: groqProvider.selectedModel,
        source: widget.source,
        sourcePage: widget.sourcePage,
        sourceSection: widget.sourceSection,
      );

      if (!mounted) return;

      // Step 4: Validating
      await _updateGenerationProgress('Validating generated questions...', 0.8);

      if (!mounted) return;

      // Increment quota usage
      await quotaProvider.incrementUsage();

      // Validate questions
      final issues = generationService.validateQuestions(questions);
      if (issues.isNotEmpty && mounted) {
        setState(() {
          _isGenerating = false;
          _generationProgress = 0.0;
        });
        await DialogService.showError(
          context,
          'The generated questions contain placeholder or invalid distractors and cannot be saved.\n\nIssue: ${issues.first}',
        );
        return;
      }

      // Step 5: Saving
      await _updateGenerationProgress('Preparing review screen...', 0.9);

      if (!mounted) return;

      // Persist the generation to history before navigating.
      final generationId = DateTime.now().millisecondsSinceEpoch.toString();
      final cleanedSource = TextNormalizationService.cleanForDisplay(widget.sourceText);
      final recent = RecentGeneration(
        id: generationId,
        title: RecentGenerationRepository.buildTitle(widget.source, _selectedType, questions.length),
        sourceFile: widget.source,
        generatedAt: DateTime.now(),
        questionCount: questions.length,
        questionsJson: questions.map((q) => q.toJson()).toList(),
        type: _selectedType,
        difficulty: _selectedDifficulty,
        style: _selectedStyle,
        sourceText: cleanedSource,
      );
      context.read<RecentGenerationRepository>().addGeneration(recent);

      // Navigate to review screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuestionReviewScreen(
            questions: questions,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            style: _selectedStyle,
            source: widget.source,
            sourceText: cleanedSource,
            sourcePage: widget.sourcePage,
            sourceSection: widget.sourceSection,
            generationId: generationId,
          ),
        ),
      );

      // Reset the generation state now that the review screen owns the flow.
      // Without this, returning from Review leaves the Configure screen stuck
      // in an infinite "Generating Questions..." state.
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationProgress = 0.0;
          _generationStep = '';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _generationProgress = 0.0;
        _generationStep = '';
      });

      if (mounted) {
        final message = e.toString().toLowerCase();
        if (message.contains('document does not contain enough usable content')) {
          final friendlyMessage = e.toString().replaceFirst('Exception: ', '');
          await DialogService.showError(
            context,
            friendlyMessage,
            title: 'Not enough content',
          );
        } else if (message.contains('socket') ||
            message.contains('network') ||
            message.contains('connection') ||
            message.contains('host') ||
            message.contains('failed host lookup')) {
          await DialogService.showNoInternet(
            context,
            onRetry: () => _startGeneration(),
          );
        } else {
          await DialogService.showError(
            context,
            'Generation failed. Please try again.',
          );
        }
      }
    }
  }

  Future<void> _showQuotaExceededDialog() async {
    if (!mounted) return;
    await DialogService.showQuotaExceeded(context);
  }

  Widget _buildGeneratingButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 16),
        Text(_generationStep.isEmpty ? 'Generating...' : _generationStep),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${(_generationProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _generationProgress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _generationStep,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGenerationProgress(String step, double progress) async {
    setState(() {
      _generationStep = step;
      _generationProgress = progress;
    });
    
    // Add a small delay to show the progress
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
