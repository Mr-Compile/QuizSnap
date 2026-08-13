import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import 'create_folder_screen.dart';
import 'rename_folder_dialog.dart';
import '../../core/services/dialog_service.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Folders',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.folderRepository.getAllFolders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              final folders = snapshot.data ?? [];

              if (folders.isEmpty) {
                return EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'No folders yet',
                  subtitle: 'Create your first folder to organize your decks',
                  action: ElevatedButton(
                    onPressed: () => _navigateToCreateFolder(context),
                    child: const Text('Create Folder'),
                  ),
                );
              }

              return ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return _buildFolderCard(context, folder);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateFolder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateFolder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateFolderScreen(),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToFolderDetails(BuildContext context, dynamic folder) {
    GoRouter.of(context).push('/folders/${folder.id}');
  }

  Widget _buildFolderCard(BuildContext context, dynamic folder) {
    return CustomCard(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToFolderDetails(context, folder),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(folder.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: AppTheme.labelLarge,
                        ),
                        if (folder.description != null) ...[
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            folder.description!,
                            style: AppTheme.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        FutureBuilder<int>(
                          future: context.read<DatabaseProvider>().deckRepository.getDeckCountForFolder(folder.id),
                          builder: (context, countSnapshot) {
                            final count = countSnapshot.data ?? 0;
                            return Text(
                              '$count deck${count == 1 ? '' : 's'}',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _onFolderMenuSelected(context, folder, value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onFolderMenuSelected(BuildContext context, dynamic folder, String value) async {
    if (!context.mounted) return;
    final dbProvider = context.read<DatabaseProvider>();
    if (value == 'rename') {
      final result = await showDialog(
        context: context,
        builder: (context) => RenameFolderDialog(
          folderId: folder.id,
          currentName: folder.name,
          currentDescription: folder.description,
        ),
      );
      if (result == true && context.mounted) {
        setState(() {});
      }
    } else if (value == 'delete') {
      final confirmed = await DialogService.showConfirmation(
        context,
        'Delete folder "${folder.name}"? Decks in this folder will become ungrouped.',
        isDestructive: true,
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await dbProvider.folderRepository.deleteFolder(folder.id);
        if (context.mounted) setState(() {});
      } catch (e) {
        if (context.mounted) DialogService.showError(context, 'Error deleting folder: $e');
      }
    }
  }
}
