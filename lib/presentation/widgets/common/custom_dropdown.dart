import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Dropdown item model
class DropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isEnabled;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.isEnabled = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropdownItem<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Custom Dropdown widget following Clean Architecture principles
/// Requirements: 1.5, 10.2, 16.1
class CustomDropdown<T> extends StatelessWidget {
  /// List of dropdown items
  final List<DropdownItem<T>> items;

  /// Currently selected value
  final T? value;

  /// Callback when value changes
  final ValueChanged<T?>? onChanged;

  /// Label text displayed above the dropdown
  final String? labelText;

  /// Hint text shown when no value is selected
  final String? hintText;

  /// Helper text shown below the dropdown
  final String? helperText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Whether the dropdown is required (shows asterisk)
  final bool isRequired;

  /// Form field validator
  final String? Function(T?)? validator;

  /// Border radius override
  final double? borderRadius;

  /// Fill color override
  final Color? fillColor;

  /// Whether to display icons in dropdown items
  final bool showItemIcons;

  /// Maximum height of the dropdown menu
  final double? menuMaxHeight;

  const CustomDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.isRequired = false,
    this.validator,
    this.borderRadius,
    this.fillColor,
    this.showItemIcons = true,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppTheme.borderRadiusMedium;

    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) => _buildDropdownItem(item)).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: _buildLabelText(),
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        filled: true,
        fillColor: fillColor ?? AppTheme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
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
      style: AppTheme.body,
      dropdownColor: AppTheme.surfaceColor,
      menuMaxHeight: menuMaxHeight,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.textSecondary,
      ),
      isExpanded: true,
    );
  }

  DropdownMenuItem<T> _buildDropdownItem(DropdownItem<T> item) {
    return DropdownMenuItem<T>(
      value: item.value,
      enabled: item.isEnabled,
      child: Row(
        children: [
          if (showItemIcons && item.icon != null) ...[
            Icon(
              item.icon,
              size: AppTheme.iconSizeMedium,
              color: item.isEnabled
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.padding8),
          ],
          Expanded(
            child: Text(
              item.label,
              style: AppTheme.body.copyWith(
                color: item.isEnabled
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}

/// Simple string dropdown for common use cases
class SimpleDropdown extends StatelessWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool enabled;
  final bool isRequired;
  final String? Function(String?)? validator;

  const SimpleDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.isRequired = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      items: items
          .map((item) => DropdownItem<String>(
                value: item,
                label: item,
              ))
          .toList(),
      value: value,
      onChanged: onChanged,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      enabled: enabled,
      isRequired: isRequired,
      validator: validator,
      showItemIcons: false,
    );
  }
}

/// Searchable dropdown with filtering capability
class SearchableDropdown<T> extends StatefulWidget {
  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? searchHintText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool enabled;
  final bool isRequired;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.searchHintText = 'Search...',
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.isRequired = false,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<DropdownItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() {});
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: AppTheme.borderRadiusMediumAll,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: AppTheme.borderRadiusMediumAll,
                border: Border.all(color: AppTheme.textHint),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.padding8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: widget.searchHintText,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.padding12,
                          vertical: AppTheme.padding8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.borderRadiusMediumAll,
                        ),
                      ),
                      onChanged: _filterItems,
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.value == widget.value;
                        return ListTile(
                          dense: true,
                          leading: item.icon != null
                              ? Icon(
                                  item.icon,
                                  size: AppTheme.iconSizeMedium,
                                )
                              : null,
                          title: Text(
                            item.label,
                            style: AppTheme.body.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          onTap: item.isEnabled
                              ? () {
                                  widget.onChanged?.call(item.value);
                                  _removeOverlay();
                                  _searchController.clear();
                                  _filteredItems = widget.items;
                                  setState(() {});
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) =>
                item.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  String? _getSelectedLabel() {
    if (widget.value == null) return null;
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownItem(value: widget.value as T, label: ''),
    );
    return selectedItem.label.isEmpty ? null : selectedItem.label;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = AppTheme.borderRadiusMedium;
    final selectedLabel = _getSelectedLabel();

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled ? _toggleDropdown : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.isRequired && widget.labelText != null
                ? '${widget.labelText} *'
                : widget.labelText,
            hintText: widget.hintText,
            errorText: widget.errorText,
            filled: true,
            fillColor: AppTheme.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.padding16,
              vertical: AppTheme.padding12,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppTheme.textSecondary,
                  )
                : null,
            suffixIcon: Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
            ),
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
          ),
          child: Text(
            selectedLabel ?? widget.hintText ?? '',
            style: AppTheme.body.copyWith(
              color:
                  selectedLabel != null ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
