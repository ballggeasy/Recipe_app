import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool filled;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = filled ? AppTheme.prim(context) : AppTheme.primLight(context);
    final selectedFg = filled ? Colors.white : AppTheme.prim(context);
    final unselectedBg = AppTheme.surf(context);
    final unselectedFg = AppTheme.txtPrimary(context);
    final borderColor = isSelected ? selectedBg : AppTheme.div(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? selectedFg : unselectedFg,
            ),
          ),
        ),
      ),
    );
  }
}
