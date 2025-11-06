import 'package:flutter/material.dart';
import '../../../core/theme/enterprise_dark_theme.dart';

/// Category navigation widget for filtering properties/vehicles
class HomeCategoryNavigation extends StatefulWidget {
  const HomeCategoryNavigation({
    super.key,
    required this.categories,
    required this.categoryIcons,
    required this.selectedIndex,
    required this.onCategorySelected,
    required this.theme,
    required this.isDark,
    this.onClearFilter,
  });

  final List<String> categories;
  final List<IconData> categoryIcons;
  final int selectedIndex;
  final Function(int) onCategorySelected;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback? onClearFilter;

  @override
  State<HomeCategoryNavigation> createState() => _HomeCategoryNavigationState();
}

class _HomeCategoryNavigationState extends State<HomeCategoryNavigation> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final left = offset > 4;
    final right = offset < (max - 4);
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? EnterpriseDarkTheme.primaryText : Colors.black87,
                  ),
                ),
              ),
              if (widget.onClearFilter != null)
                TextButton(
                  onPressed: widget.selectedIndex == 0 ? null : widget.onClearFilter,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.selectedIndex == 0
                          ? (isDark ? EnterpriseDarkTheme.secondaryText : Colors.grey)
                          : (isDark ? EnterpriseDarkTheme.primaryAccent : theme.primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.categories.length,
                itemBuilder: (context, index) => _buildCategoryItem(index),
              ),
              if (_canScrollLeft)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _GradientArrow(
                      isLeft: true,
                      onTap: () => _scrollBy(-120),
                      theme: theme,
                      height: 52,
                    ),
                  ),
                ),
              if (_canScrollRight)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _GradientArrow(
                      isLeft: false,
                      onTap: () => _scrollBy(120),
                      theme: theme,
                      height: 56,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(int index) {
    final isSelected = index == widget.selectedIndex;
    final theme = widget.theme;
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: () => widget.onCategorySelected(index),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                      : theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: (isDark
                            ? EnterpriseDarkTheme.primaryAccent
                            : theme.primaryColor)
                        .withOpacity(isDark ? 0.18 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                widget.categoryIcons[index],
                color: isSelected
                    ? (isDark ? EnterpriseDarkTheme.primaryAccent : theme.primaryColor)
                    : (isDark ? EnterpriseDarkTheme.secondaryText : Colors.grey[600]),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.categories[index],
              style: TextStyle(
                fontSize: 10,
                height: 1.05,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? (isDark ? EnterpriseDarkTheme.primaryAccent : theme.primaryColor)
                    : (isDark ? EnterpriseDarkTheme.secondaryText : Colors.grey[600]),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientArrow extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onTap;
  final ThemeData theme;
  final double? height;

  const _GradientArrow({
    required this.isLeft,
    required this.onTap,
    required this.theme,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 36,
          height: height,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? EnterpriseDarkTheme.primaryBorder.withOpacity(0.35)
                        : theme.colorScheme.outline.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.white,
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: (theme.brightness == Brightness.dark
                              ? EnterpriseDarkTheme.primaryAccent
                              : theme.primaryColor)
                          .withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(5, 5),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  isLeft ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
