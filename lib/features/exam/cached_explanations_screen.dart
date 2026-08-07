import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/services/explanation_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'full_explanation_screen.dart';

class CachedExplanationsScreen extends StatefulWidget {
  const CachedExplanationsScreen({super.key});

  @override
  State<CachedExplanationsScreen> createState() => _CachedExplanationsScreenState();
}

class _CachedExplanationsScreenState extends State<CachedExplanationsScreen> {
  bool _isLoading = true;
  List<CachedExplanation> _explanations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExplanations();
  }

  Future<void> _loadExplanations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examProvider = context.read<ExamProvider>();
      final explanations = await examProvider.getAllCachedExplanations();

      setState(() {
        _explanations = explanations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearExpiredCache() async {
    final examProvider = context.read<ExamProvider>();
    await examProvider.clearExpiredCache();
    await _loadExplanations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expired explanations cleared')),
      );
    }
  }

  Future<void> _clearAllCache() async {
    final examProvider = context.read<ExamProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text('Are you sure you want to delete all cached explanations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await examProvider.clearCache();
      await _loadExplanations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All explanations cleared')),
        );
      }
    }
  }

  Future<void> _deleteExplanation(String questionId) async {
    final examProvider = context.read<ExamProvider>();
    await examProvider.clearExplanation(questionId);
    await _loadExplanations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Explanation deleted')),
      );
    }
  }

  void _viewExplanation(CachedExplanation cached) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullExplanationScreen(
          question: cached.question,
          explanation: cached.explanation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cached Explanations',
        actions: [
          if (_explanations.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear_expired':
                    _clearExpiredCache();
                    break;
                  case 'clear_all':
                    _clearAllCache();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_expired',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 8),
                      Text('Clear Expired'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const ListSkeleton(itemCount: 5)
          : _errorMessage != null
              ? _buildErrorState()
              : _explanations.isEmpty
                  ? _buildEmptyState()
                  : _buildExplanationsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Error loading explanations',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _errorMessage!,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          CustomButton(
            text: 'Retry',
            onPressed: _loadExplanations,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.lightbulb_outline,
      title: 'No cached explanations',
      subtitle: 'AI explanations will be cached here as you review exam answers',
    );
  }

  Widget _buildExplanationsList() {
    return Column(
      children: [
        _buildCacheInfo(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: _explanations.length,
            itemBuilder: (context, index) {
              final cached = _explanations[index];
              return _buildExplanationCard(cached, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCacheInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.storage,
            '${_explanations.length}',
            'Total',
          ),
          _buildInfoItem(
            Icons.schedule,
            '7 days',
            'Retention',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(CachedExplanation cached, int index) {
    final isExpired = cached.isExpired;
    final daysSinceCache = DateTime.now().difference(cached.cachedAt).inDays;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      color: isExpired
          ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cached.question.question,
                      style: AppTheme.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isExpired
                              ? Colors.grey
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired 
                              ? 'Expired'
                              : daysSinceCache == 0 
                                  ? 'Today'
                                  : '$daysSinceCache days ago',
                          style: AppTheme.bodySmall.copyWith(
                            color: isExpired
                                ? Colors.grey
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteExplanation(cached.questionId),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Explanation',
                  onPressed: isExpired ? null : () => _viewExplanation(cached),
                  isOutlined: true,
                  icon: Icons.visibility,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
