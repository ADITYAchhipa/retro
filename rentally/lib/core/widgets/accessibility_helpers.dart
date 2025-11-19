import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Comprehensive accessibility helpers for industrial-grade app
class AccessibilityHelpers {
  /// Create semantic label for screen readers
  static String createSemanticLabel(String text, {String? context}) {
    if (context != null) {
      return '$text, $context';
    }
    return text;
  }

  /// Announce to screen readers
  static void announce(BuildContext context, String message) {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Create accessible button
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? tooltip,
    bool excludeSemantics = false,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: excludeSemantics,
      child: button,
    );
  }

  /// Create accessible text field
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? semanticLabel,
    bool required = false,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }

  /// Create accessible card with proper semantics
  static Widget accessibleCard({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    Widget card = Card(child: child);

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        child: card,
      );
    }

    if (tooltip != null) {
      card = Tooltip(
        message: tooltip,
        child: card,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }

  /// Create accessible image with alt text
  static Widget accessibleImage({
    required ImageProvider image,
    required String altText,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      label: altText,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: altText,
      ),
    );
  }

  /// Create accessible list item
  static Widget accessibleListItem({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: ListTile(
        onTap: onTap,
        selected: selected,
        title: child,
      ),
    );
  }

  /// Create accessible tab bar
  static Widget accessibleTabBar({
    required List<Tab> tabs,
    required TabController controller,
    required List<String> semanticLabels,
  }) {
    return Semantics(
      container: true,
      child: TabBar(
        controller: controller,
        tabs: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          return Semantics(
            label: semanticLabels[index],
            selected: controller.index == index,
            button: true,
            child: tab,
          );
        }).toList(),
      ),
    );
  }

  /// Create accessible progress indicator
  static Widget accessibleProgressIndicator({
    double? value,
    String? semanticLabel,
    String? semanticValue,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Loading',
      value: semanticValue ?? (value != null ? '${(value * 100).round()}%' : null),
      child: LinearProgressIndicator(value: value),
    );
  }

  /// Create accessible switch
  static Widget accessibleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return Semantics(
      label: label,
      toggled: value,
      child: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Create accessible checkbox
  static Widget accessibleCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return Semantics(
      label: label,
      checked: value,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Create accessible radio button
  static Widget accessibleRadio<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return Semantics(
      label: label,
      inMutuallyExclusiveGroup: true,
      checked: value == groupValue,
      child: RadioGroup<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: Radio<T>(
          value: value,
        ),
      ),
    );
  }

  /// Create accessible slider
  static Widget accessibleSlider({
    required double value,
    required ValueChanged<double> onChanged,
    required String label,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
  }) {
    return Semantics(
      label: label,
      value: value.toString(),
      increasedValue: (value + (max - min) / (divisions ?? 100)).toString(),
      decreasedValue: (value - (max - min) / (divisions ?? 100)).toString(),
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }

  /// Focus management helpers
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// High contrast color helper
  static Color getHighContrastColor(BuildContext context, Color baseColor) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    if (brightness == Brightness.dark) {
      return baseColor.computeLuminance() > 0.5 
          ? baseColor 
          : Colors.white;
    } else {
      return baseColor.computeLuminance() < 0.5 
          ? baseColor 
          : Colors.black;
    }
  }

  /// Text scale factor helper
  static double getAccessibleTextScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaler.scale(1.0).clamp(1.0, 2.0);
  }

  /// Create accessible app bar
  static PreferredSizeWidget accessibleAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  /// Create accessible bottom navigation
  static Widget accessibleBottomNavigation({
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<BottomNavigationBarItem> items,
    required List<String> semanticLabels,
  }) {
    return Semantics(
      container: true,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BottomNavigationBarItem(
            icon: Semantics(
              label: semanticLabels[index],
              selected: currentIndex == index,
              button: true,
              child: item.icon,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

/// Accessibility wrapper widget
class AccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final bool excludeSemantics;
  final bool button;
  final bool header;
  final bool textField;
  final bool image;
  final VoidCallback? onTap;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.button = false,
    this.header = false,
    this.textField = false,
    this.image = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    return Semantics(
      label: semanticLabel,
      excludeSemantics: excludeSemantics,
      button: button,
      header: header,
      textField: textField,
      image: image,
      child: result,
    );
  }
}
