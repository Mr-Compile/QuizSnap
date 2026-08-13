import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import 'exam_question_screen.dart';

class CountdownScreen extends StatefulWidget {
  final String examId;

  const CountdownScreen({
    super.key,
    required this.examId,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  int _countdown = 5;
  Timer? _timer;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _isStarting = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _beginExam();
        }
      });
    });
  }

  void _beginExam() {
    _timer?.cancel();
    
    if (mounted) {
      final examProvider = context.read<ExamProvider>();
      examProvider.startExam();
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExamQuestionScreen(
            examId: widget.examId,
          ),
        ),
      );
    }
  }

  void _skipCountdown() {
    _timer?.cancel();
    _beginExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final exam = examProvider.currentExam;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exam info
                if (exam != null) ...[
                  Icon(
                    Icons.quiz,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    'Get Ready!',
                    style: AppTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    exam.deckName,
                    style: AppTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildInfoRow(
                    Icons.help_outline,
                    '${exam.totalQuestions} Questions',
                  ),
                  _buildInfoRow(
                    Icons.timer_outlined,
                    '${exam.timeLimit} Minutes',
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],

                // Countdown display
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _countdown > 0 ? '$_countdown' : 'GO!',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Skip button
                if (_isStarting && _countdown > 2)
                  CustomButton(
                    text: 'Skip Countdown',
                    onPressed: _skipCountdown,
                    isOutlined: true,
                  ),

                const SizedBox(height: AppTheme.spacingLg),

                // Tips
                CustomButton(
                  text: 'Cancel',
                  onPressed: () {
                    _timer?.cancel();
                    examProvider.clearExam();
                    Navigator.of(context).pop();
                  },
                  isSecondary: true,
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            text,
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
