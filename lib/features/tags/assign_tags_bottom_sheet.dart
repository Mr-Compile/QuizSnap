import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/dialog_service.dart';

class AssignTagsBottomSheet extends StatefulWidget {
  final int flashcardId;

  const AssignTagsBottomSheet({
    super.key,
    required this.flashcardId,
  });

  @override
  State<AssignTagsBottomSheet> createState() => _AssignTagsBottomSheetState();
}

class _AssignTagsBottomSheetState extends State<AssignTagsBottomSheet> {
  List<int> _selectedTagIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final tags = await dbProvider.tagRepository.getTagsForFlashcard(widget.flashcardId);
    
    if (mounted) {
      setState(() {
        _selectedTagIds = tags.map((tag) => tag.id).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Tags',
                  style: AppTheme.textSmall,
                ),
                TextButton(
                  onPressed: _isLoading ? null : _saveTags,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingXl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Consumer<DatabaseProvider>(
              builder: (context, dbProvider, child) {
                return FutureBuilder(
                  future: dbProvider.tagRepository.getAllTags(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final tags = snapshot.data ?? [];

                    if (tags.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        child: Text(
                          'No tags available. Create tags first.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        final isSelected = _selectedTagIds.contains(tag.id);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Text(tag.name),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  void _saveTags() async {
    final dbProvider = context.read<DatabaseProvider>();

    try {
      await dbProvider.tagRepository.setFlashcardTags(widget.flashcardId, _selectedTagIds);

      if (mounted) {
        await DialogService.showSuccess(context, 'Tags updated successfully');
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error updating tags: $e');
      }
    }
  }
}
