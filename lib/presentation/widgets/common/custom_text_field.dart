import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

/// Custom TextField widget following Clean Architecture principles
/// Requirements: 1.5, 10.2, 16.1
/// CRITICAL - Shared component used by all developers
class CustomTextField extends StatelessWidget {
  /// Text controller for the field
  final TextEditingController? controller;

  /// Label text displayed above/inside the field
  final String? labelText;

  /// Hint text shown when field is empty
  final String? hintText;

  /// Helper text shown below the field
  final String? helperText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Prefix icon displayed at the start of the field
  final IconData? prefixIcon;

  /// Suffix icon displayed at the end of the field
  final IconData? suffixIcon;

  /// Callback when suffix icon is tapped
  final VoidCallback? onSuffixIconTap;

  /// Whether the field is obscured (for passwords)
  final bool obscureText;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is read-only
  final bool readOnly;

  /// Maximum number of lines
  final int maxLines;

  /// Minimum number of lines
  final int minLines;

  /// Maximum length of input
  final int? maxLength;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Input formatters for validation
  final List<TextInputFormatter>? inputFormatters;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Callback when field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Callback when field is tapped
  final VoidCallback? onTap;

  /// Form field validator
  final String? Function(String?)? validator;

  /// Focus node for the field
  final FocusNode? focusNode;

  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Whether to auto-correct
  final bool autocorrect;

  /// Whether to enable suggestions
  final bool enableSuggestions;

  /// Content padding override
  final EdgeInsetsGeometry? contentPadding;

  /// Border radius override
  final double? borderRadius;

  /// Fill color override
  final Color? fillColor;

  /// Whether the field is required (shows asterisk)
  final bool isRequired;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? AppTheme.borderRadiusMedium;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: AppTheme.body,
      decoration: InputDecoration(
        labelText: _buildLabelText(),
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        filled: true,
        fillColor: fillColor ?? AppTheme.surfaceColor,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: AppTheme.padding16,
              vertical: AppTheme.padding12,
            ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: errorText != null
                    ? AppTheme.errorColor
                    : AppTheme.textSecondary,
                size: AppTheme.iconSizeMedium,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixIconTap,
                child: Icon(
                  suffixIcon,
                  color: errorText != null
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                  size: AppTheme.iconSizeMedium,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          borderSide: BorderSide(color: AppTheme.textHint.withOpacity(0.5)),
        ),
        labelStyle: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
        errorStyle: AppTheme.caption.copyWith(color: AppTheme.errorColor),
        helperStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}

/// Password text field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool isRequired;

  const PasswordTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.isRequired = false,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      isRequired: widget.isRequired,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: _obscureText ? Icons.visibility_off : Icons.visibility,
      onSuffixIconTap: _toggleVisibility,
      keyboardType: TextInputType.visiblePassword,
    );
  }
}

/// Email text field with email keyboard
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool isRequired;

  const EmailTextField({
    super.key,
    this.controller,
    this.labelText = 'Email',
    this.hintText = 'Enter your email',
    this.errorText,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      isRequired: isRequired,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enableSuggestions: false,
    );
  }
}

/// Search text field with search icon and clear button
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true ? Icons.clear : null,
      onSuffixIconTap: () {
        controller?.clear();
        onClear?.call();
      },
      textInputAction: TextInputAction.search,
      borderRadius: AppTheme.borderRadiusRound,
    );
  }
}

/// Multiline text field for longer text input
class MultilineTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool isRequired;

  const MultilineTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      onChanged: onChanged,
      validator: validator,
      isRequired: isRequired,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
