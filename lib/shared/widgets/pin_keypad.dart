import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// A modern, reusable PIN entry widget with dot indicators and a
/// large numeric keypad.
///
/// Used by the Set PIN, Change PIN, and Lock screens so the PIN entry
/// experience is consistent across the app.
///
/// Features:
/// * Obscured PIN dots (● ○) — the actual PIN is never displayed.
/// * Large 48dp+ touch-target keypad buttons with haptic feedback.
/// * Configurable length range (default 4–6 digits).
/// * Auto-submits when [maxLength] is reached (optional).
/// * Error state with shake animation and accessible semantics.
/// * Theme-aware surfaces, text, and icons for light/dark mode.
class PinKeypad extends StatefulWidget {
  /// Called whenever the entered PIN changes.
  final ValueChanged<String>? onChanged;

  /// Called when the PIN reaches [maxLength] (auto-submit) or when the
  /// user explicitly presses the primary action button.
  final ValueChanged<String>? onSubmit;

  /// Maximum number of digits the PIN can hold.
  final int maxLength;

  /// Minimum number of digits required before submission is allowed.
  final int minLength;

  /// When true, the keypad auto-submits as soon as [maxLength] digits
  /// are entered. Set to false when a separate "Continue" button is used.
  final bool autoSubmit;

  /// When non-null, shows an error message below the dots and triggers
  /// a shake animation. Pass null to clear the error.
  final String? errorText;

  /// Disables all input (e.g. during loading or lockout).
  final bool enabled;

  /// Optional label shown above the dots (e.g. "Enter your PIN").
  final String? label;

  const PinKeypad({
    super.key,
    this.onChanged,
    this.onSubmit,
    this.maxLength = 6,
    this.minLength = 4,
    this.autoSubmit = false,
    this.errorText,
    this.enabled = true,
    this.label,
  });

  @override
  State<PinKeypad> createState() => PinKeypadState();
}

class PinKeypadState extends State<PinKeypad>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PinKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation when an error appears.
    if (widget.errorText != null && oldWidget.errorText == null) {
      _shake();
    }
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  /// Public method to clear the entered PIN (used by parent screens
  /// after a failed attempt).
  void clear() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = '');
      widget.onChanged?.call('');
    }
  }

  void _appendDigit(String digit) {
    if (!widget.enabled) return;
    if (_pin.length >= widget.maxLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    widget.onChanged?.call(_pin);
    if (widget.autoSubmit && _pin.length == widget.maxLength) {
      widget.onSubmit?.call(_pin);
    }
  }

  void _backspace() {
    if (!widget.enabled) return;
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    widget.onChanged?.call(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing4),
        ],

        // PIN dots with shake animation
        Semantics(
          label: 'PIN entry. ${_pin.length} digits entered.',
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = _shakeController.isAnimating
                  ? (Curves.easeInOut.transform(
                          (_shakeController.value * 3).roundToDouble() % 2 == 0
                              ? _shakeController.value
                              : 1 - _shakeController.value) -
                      0.5)
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset * 16, 0),
                child: child,
              );
            },
            child: _buildDots(colorScheme, errorColor),
          ),
        ),

        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: AppTheme.spacing3),
          Text(
            widget.errorText!,
            style: AppTheme.bodySmall.copyWith(color: errorColor),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: AppTheme.spacing6),

        // Numeric keypad
        _buildKeypad(context, colorScheme),
      ],
    );
  }

  Widget _buildDots(ColorScheme colorScheme, Color errorColor) {
    final isError = widget.errorText != null;
    final activeColor = isError ? errorColor : colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxLength, (index) {
        final filled = index < _pin.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? activeColor : Colors.transparent,
              border: Border.all(
                color: filled
                    ? activeColor
                    : colorScheme.onSurface.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(BuildContext context, ColorScheme colorScheme) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final buttonSize = isTablet ? 80.0 : 72.0;
    final fontSize = isTablet ? 28.0 : 24.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 360 : 300),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((d) => _buildKey(
                          digit: d,
                          buttonSize: buttonSize,
                          fontSize: fontSize,
                          colorScheme: colorScheme,
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Empty spacer to align 0 and backspace.
                SizedBox(width: buttonSize, height: buttonSize),
                _buildKey(
                  digit: '0',
                  buttonSize: buttonSize,
                  fontSize: fontSize,
                  colorScheme: colorScheme,
                ),
                _buildBackspace(buttonSize, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey({
    required String digit,
    required double buttonSize,
    required double fontSize,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Semantics(
        button: true,
        label: 'Digit $digit',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? () => _appendDigit(digit) : null,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              alignment: Alignment.center,
              child: Text(
                digit,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: AppTheme.fontMedium,
                  color: widget.enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace(double buttonSize, ColorScheme colorScheme) {
    final canDelete = widget.enabled && _pin.isNotEmpty;
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Semantics(
        button: true,
        label: 'Delete',
        enabled: canDelete,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canDelete ? _backspace : null,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                Icons.backspace_outlined,
                size: 26,
                color: canDelete
                    ? colorScheme.onSurface.withValues(alpha: 0.7)
                    : colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
