import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/success_snackbar.dart';
import 'create_tag_dialog.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tags',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.tagRepository.getAllTags(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return ErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              final tags = snapshot.data ?? [];

              if (tags.isEmpty) {
                return EmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No tags yet',
                  subtitle: 'Create tags to organize your flashcards',
                  action: ElevatedButton(
                    onPressed: () => _showCreateTagDialog(context),
                    child: const Text('Create Tag'),
                  ),
                );
              }

              return ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return CustomCard(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Text(
                            tag.name,
                            style: AppTheme.labelLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _confirmDelete(context, tag),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTagDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTagDialog(),
    ).then((_) => setState(() {}));
  }

  void _confirmDelete(BuildContext context, dynamic tag) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Tag',
      message: 'Are you sure you want to delete "${tag.name}"? This will remove the tag from all flashcards.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    if (!mounted) return;

    final dbProvider = this.context.read<DatabaseProvider>();
    try {
      await dbProvider.tagRepository.deleteTag(tag.id);
      if (!mounted) return;
      SuccessSnackbar.show(
        this.context,
        message: 'Tag deleted successfully',
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(this.context);
      final errorColor = Theme.of(this.context).colorScheme.error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting tag: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
