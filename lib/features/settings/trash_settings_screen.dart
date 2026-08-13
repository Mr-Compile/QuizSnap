import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/trash_cleanup_service.dart';
import '../../core/services/trash_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class TrashSettingsScreen extends StatefulWidget {
  const TrashSettingsScreen({super.key});

  @override
  State<TrashSettingsScreen> createState() => _TrashSettingsScreenState();
}

class _TrashSettingsScreenState extends State<TrashSettingsScreen> {
  bool _autoDelete = true;
  bool _isLoading = true;
  int _deckCount = 0;
  int _flashcardCount = 0;
  DateTime? _lastCleanup;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final db = context.read<DatabaseProvider>();
    final prefs = await SharedPreferences.getInstance();
    final decks = await db.deckRepository.getDeletedDecks();
    final cards = await db.flashcardRepository.getDeletedFlashcards();

    final autoDelete = await TrashCleanupService.isAutoDeleteEnabled(prefs);
    if (mounted) {
      setState(() {
        _autoDelete = autoDelete;
        _deckCount = decks.length;
        _flashcardCount = cards.length;
        _lastCleanup = null; // loaded later via prefs
        _isLoading = false;
      });
    }

    final last = await TrashCleanupService.lastCleanup(prefs);
    if (mounted) {
      setState(() => _lastCleanup = last);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Trash Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              children: [
                _buildInfoCard(),
                const SizedBox(height: AppTheme.spacingLg),
                Card(
                  child: SwitchListTile(
                    title: const Text('Auto-delete trash after 30 days'),
                    subtitle: const Text('Permanently remove items after 30 days in trash.'),
                    value: _autoDelete,
                    onChanged: _toggleAutoDelete,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                CustomButton(
                  text: 'Empty Trash Now',
                  icon: Icons.delete_forever,
                  onPressed: _isLoading ? null : _emptyTrashNow,
                  fullWidth: true,
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trash contents', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoRow('Deleted decks', '$_deckCount'),
            _buildInfoRow('Deleted flashcards', '$_flashcardCount'),
            _buildInfoRow(
              'Last cleanup',
              _lastCleanup == null
                  ? 'Never'
                  : '${_lastCleanup!.day}/${_lastCleanup!.month}/${_lastCleanup!.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _toggleAutoDelete(bool? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await TrashCleanupService.setAutoDeleteEnabled(prefs, value);
    setState(() => _autoDelete = value);
  }

  Future<void> _emptyTrashNow() async {
    setState(() => _isLoading = true);

    final db = context.read<DatabaseProvider>();
    final service = TrashService(
      deckRepository: db.deckRepository,
      flashcardRepository: db.flashcardRepository,
    );

    try {
      await service.emptyTrash();
      await _loadState();
      if (mounted) {
        await DialogService.showSuccess(context, 'Trash emptied');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error emptying trash: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
