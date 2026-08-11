import 'package:flutter/material.dart';
import 'custom_card.dart';

class FilePathCard extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String fileSize;
  final DateTime? createdAt;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onCopyPath;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;

  const FilePathCard({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.createdAt,
    this.onOpenFolder,
    this.onCopyPath,
    this.onShare,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilePathDisplay(context),
          const SizedBox(height: 12),
          _buildFileDetails(context),
          const SizedBox(height: 12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildFilePathDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            filePath,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFileDetails(BuildContext context) {
    return Row(
      children: [
        _buildDetailChip(context, Icons.storage, fileSize),
        const SizedBox(width: 8),
        if (createdAt != null)
          _buildDetailChip(
            context,
            Icons.access_time,
            _formatDate(createdAt!),
          ),
      ],
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onOpenFolder != null)
          Expanded(
            child: _buildActionButton(
              context,
              Icons.folder_open,
              'Open Folder',
              onOpenFolder!,
            ),
          ),
        if (onOpenFolder != null && (onCopyPath != null || onShare != null))
          const SizedBox(width: 8),
        if (onCopyPath != null)
          Expanded(
            child: _buildActionButton(
              context,
              Icons.copy,
              'Copy Path',
              onCopyPath!,
            ),
          ),
        if (onCopyPath != null && onShare != null)
          const SizedBox(width: 8),
        if (onShare != null)
          Expanded(
            child: _buildActionButton(
              context,
              Icons.share,
              'Share',
              onShare!,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class FilePathSnackBar {
  static void show(
    BuildContext context, {
    required String filePath,
    required String fileName,
    required String fileSize,
    DateTime? createdAt,
    VoidCallback? onOpenFolder,
    VoidCallback? onCopyPath,
    VoidCallback? onShare,
    Duration duration = const Duration(seconds: 8),
  }) {
    final snackBar = SnackBar(
      content: FilePathCard(
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: createdAt,
        onOpenFolder: onOpenFolder,
        onCopyPath: onCopyPath,
        onShare: onShare,
        onDismiss: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
