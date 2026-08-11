import 'package:flutter/material.dart';
import '../../core/models/backup_enhanced.dart';

class ScheduleSettingsDialog extends StatefulWidget {
  final BackupSchedule currentSchedule;

  const ScheduleSettingsDialog({
    super.key,
    required this.currentSchedule,
  });

  @override
  State<ScheduleSettingsDialog> createState() => _ScheduleSettingsDialogState();
}

class _ScheduleSettingsDialogState extends State<ScheduleSettingsDialog> {
  late bool _enabled;
  late BackupFrequency _frequency;
  late BackupRetention _retention;

  @override
  void initState() {
    super.initState();
    _enabled = widget.currentSchedule.enabled;
    _frequency = widget.currentSchedule.frequency;
    _retention = widget.currentSchedule.retention;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup Schedule Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable toggle
            SwitchListTile(
              title: const Text('Enable Automatic Backup'),
              subtitle: const Text('Automatically create backups on schedule'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
            const Divider(),
            
            // Frequency selection
            const Text(
              'Backup Frequency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...BackupFrequency.values.map((freq) {
              return RadioListTile<BackupFrequency>(
                title: Text(_getFrequencyLabel(freq)),
                subtitle: Text(_getFrequencyDescription(freq)),
                value: freq,
                // ignore: deprecated_member_use
                groupValue: _frequency,
                // ignore: deprecated_member_use
                onChanged: _enabled ? (value) {
                  setState(() {
                    _frequency = value!;
                  });
                } : null,
              );
            }),
            
            const Divider(),
            
            // Retention selection
            const Text(
              'Backup Retention',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...BackupRetention.values.map((ret) {
              return RadioListTile<BackupRetention>(
                title: Text(_getRetentionLabel(ret)),
                subtitle: Text(_getRetentionDescription(ret)),
                value: ret,
                // ignore: deprecated_member_use
                groupValue: _retention,
                // ignore: deprecated_member_use
                onChanged: _enabled ? (value) {
                  setState(() {
                    _retention = value!;
                  });
                } : null,
              );
            }),
            
            if (!_enabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enable automatic backup to configure frequency and retention settings.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getFrequencyLabel(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  String _getFrequencyDescription(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Backup once every day';
      case BackupFrequency.weekly:
        return 'Backup once every week';
      case BackupFrequency.monthly:
        return 'Backup once every month';
    }
  }

  String _getRetentionLabel(BackupRetention retention) {
    switch (retention) {
      case BackupRetention.keep3:
        return 'Keep 3 backups';
      case BackupRetention.keep5:
        return 'Keep 5 backups';
      case BackupRetention.keep10:
        return 'Keep 10 backups';
    }
  }

  String _getRetentionDescription(BackupRetention retention) {
    switch (retention) {
      case BackupRetention.keep3:
        return 'Keep the most recent 3 backups';
      case BackupRetention.keep5:
        return 'Keep the most recent 5 backups';
      case BackupRetention.keep10:
        return 'Keep the most recent 10 backups';
    }
  }

  void _saveSettings() {
    final newSchedule = widget.currentSchedule.copyWith(
      enabled: _enabled,
      frequency: _frequency,
      retention: _retention,
    );
    Navigator.pop(context, newSchedule);
  }
}