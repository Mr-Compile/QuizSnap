import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/reminder_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final reminderProvider = context.read<ReminderProvider>();
    await reminderProvider.initialize();
    
    if (!mounted) return;
    
    final timeParts = reminderProvider.reminderTime.split(':');
    setState(() {
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
      
      final reminderProvider = context.read<ReminderProvider>();
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await reminderProvider.setReminderTime(timeString);
    }
  }

  void _showDayPicker() {
    final reminderProvider = context.read<ReminderProvider>();
    final selectedDays = Set<int>.from(reminderProvider.reminderDays);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Days'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int day = 1; day <= 7; day++)
              CheckboxListTile(
                title: Text(_getDayName(day)),
                value: selectedDays.contains(day),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  });
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await reminderProvider.setReminderDays(selectedDays.toList());
              if (!mounted) return;
              Navigator.pop(this.context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'custom':
        return 'Custom';
      default:
        return frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study Reminders',
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, child) {
          return ListView(
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Reminders'),
                  subtitle: Text(reminderProvider.isEnabled 
                      ? 'Study reminders are active' 
                      : 'Turn on study reminders'),
                  value: reminderProvider.isEnabled,
                  onChanged: reminderProvider.isLoading 
                      ? null 
                      : (value) async {
                          await reminderProvider.setEnabled(value);
                          if (!mounted) return;

                          if (reminderProvider.errorMessage != null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(reminderProvider.errorMessage!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              if (reminderProvider.isEnabled) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Settings',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('Time'),
                          subtitle: Text(_selectedTime.format(context)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickTime,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Frequency'),
                          subtitle: Text(_getFrequencyLabel(reminderProvider.frequency)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showFrequencyPicker(reminderProvider),
                        ),
                        if (reminderProvider.frequency != 'daily') ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.event),
                            title: const Text('Days'),
                            subtitle: Text(reminderProvider.reminderDays
                                .map((d) => _getDayName(d).substring(0, 3))
                                .join(', ')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showDayPicker,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permissions',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        FutureBuilder<bool>(
                          future: reminderProvider.arePermissionsGranted(),
                          builder: (context, snapshot) {
                            final granted = snapshot.data ?? false;
                            return ListTile(
                              leading: Icon(
                                granted ? Icons.check_circle : Icons.error_outline,
                                color: granted ? Colors.green : Colors.orange,
                              ),
                              title: const Text('Notification Permissions'),
                              subtitle: Text(granted 
                                  ? 'Permissions granted' 
                                  : 'Permissions required'),
                              trailing: !granted
                                  ? CustomButton(
                                      text: 'Grant',
                                      onPressed: () async {
                                        await reminderProvider.requestPermissions();
                                      },
                                      isOutlined: true,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingLg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Reminders',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildInfoItem(
                        icon: Icons.notifications_active,
                        title: 'Smart Notifications',
                        description: 'Get reminded at your preferred time to maintain consistent study habits',
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildInfoItem(
                        icon: Icons.schedule,
                        title: 'Flexible Scheduling',
                        description: 'Choose daily, weekly, or custom schedules that fit your routine',
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildInfoItem(
                        icon: Icons.phone_android,
                        title: 'System Notifications',
                        description: 'Uses your device\'s notification system for reliable reminders',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFrequencyPicker(ReminderProvider reminderProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Daily'),
              subtitle: const Text('Every day at the selected time'),
              value: 'daily',
              // ignore: deprecated_member_use
              groupValue: reminderProvider.frequency,
              // ignore: deprecated_member_use
              onChanged: (value) async {
                if (value != null) {
                  await reminderProvider.setFrequency(value);
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Weekly'),
              subtitle: const Text('On selected days each week'),
              value: 'weekly',
              // ignore: deprecated_member_use
              groupValue: reminderProvider.frequency,
              // ignore: deprecated_member_use
              onChanged: (value) async {
                if (value != null) {
                  await reminderProvider.setFrequency(value);
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Custom'),
              subtitle: const Text('Choose specific days and times'),
              value: 'custom',
              // ignore: deprecated_member_use
              groupValue: reminderProvider.frequency,
              // ignore: deprecated_member_use
              onChanged: (value) async {
                if (value != null) {
                  await reminderProvider.setFrequency(value);
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.bambooGreen600, size: 20),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelMedium,
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
