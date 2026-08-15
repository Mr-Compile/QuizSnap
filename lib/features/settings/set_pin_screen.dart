import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/pin_keypad.dart';
import '../../core/services/dialog_service.dart';

/// Modern Set PIN screen with a two-step PIN entry flow (enter → confirm)
/// using a large numeric keypad and dot indicators.
///
/// Hierarchy:
/// Security → PIN Lock → Set PIN → Enter PIN → Confirm PIN → Save
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  /// 0 = enter PIN, 1 = confirm PIN
  int _step = 0;
  String _firstPin = '';
  String _currentPin = '';
  String? _errorText;
  final _keypadKey = GlobalKey<PinKeypadState>();

  @override
  void dispose() {
    super.dispose();
  }

  void _onPinChanged(String pin) {
    setState(() {
      _currentPin = pin;
      if (_errorText != null) _errorText = null;
    });
  }

  void _onPinSubmitted(String pin) {
    if (_step == 0) {
      // Validate minimum length on the first step.
      if (pin.length < 4) {
        setState(() => _errorText = 'Your PIN must contain 4–6 digits.');
        return;
      }
      // Move to confirm step.
      setState(() {
        _firstPin = pin;
        _step = 1;
        _currentPin = '';
        _errorText = null;
      });
      _keypadKey.currentState?.clear();
    } else {
      // Confirm step — compare with first PIN.
      if (pin != _firstPin) {
        setState(() {
          _errorText = 'PINs do not match. Please try again.';
          _step = 0;
          _firstPin = '';
          _currentPin = '';
        });
        _keypadKey.currentState?.clear();
      } else {
        // PINs match — save.
        _savePin(pin);
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.setPin(pin);

    if (!mounted) return;

    if (success) {
      await DialogService.showSuccess(
        context,
        'PIN set successfully. Your app is now protected.',
        title: 'PIN Set',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      // Reset to step 0 so the user can re-enter.
      setState(() {
        _errorText = securityProvider.errorMessage ??
            'Something went wrong. Please try again.';
        _step = 0;
        _firstPin = '';
        _currentPin = '';
      });
      _keypadKey.currentState?.clear();
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _backToEnterStep() {
    setState(() {
      _step = 0;
      _firstPin = '';
      _currentPin = '';
      _errorText = null;
    });
    _keypadKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final securityProvider = context.watch<SecurityProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Set PIN'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing4,
            vertical: AppTheme.spacing4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PIN entry card — the primary and only content card.
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing6),
                  child: Column(
                    children: [
                      // Lock icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.bambooGreen600
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: AppTheme.bambooGreen600,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),

                      // Step title
                      Text(
                        _step == 0 ? 'Set Up Your PIN' : 'Confirm Your PIN',
                        style: AppTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing2),

                      // Step description
                      Text(
                        _step == 0
                            ? 'Enter a 4–6 digit PIN to protect your app.'
                            : 'Re-enter your PIN to confirm.',
                        style: AppTheme.bodyMedium.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing6),

                      // PIN keypad — no autoSubmit; Continue button below
                      // handles submission so 4–6 digit PINs are all valid.
                      PinKeypad(
                        key: _keypadKey,
                        maxLength: 6,
                        minLength: 4,
                        autoSubmit: false,
                        errorText: _errorText,
                        enabled: !securityProvider.isLoading,
                        onChanged: _onPinChanged,
                        onSubmit: _onPinSubmitted,
                      ),

                      const SizedBox(height: AppTheme.spacing4),

                      // Continue button — enabled when PIN has 4+ digits.
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_currentPin.length >= 4 &&
                                  !securityProvider.isLoading)
                              ? () => _onPinSubmitted(_currentPin)
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            _step == 0 ? 'Continue' : 'Save PIN',
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing2),

                      // Step indicator + secondary actions
                      if (_step == 1)
                        TextButton.icon(
                          onPressed: securityProvider.isLoading
                              ? null
                              : _backToEnterStep,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Re-enter PIN'),
                        )
                      else
                        TextButton(
                          onPressed:
                              securityProvider.isLoading ? null : _cancel,
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing6),
            ],
          ),
        ),
      ),
    );
  }

}
