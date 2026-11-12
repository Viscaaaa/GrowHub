import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BadgeChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const BadgeChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  factory BadgeChip.status(String status) {
    Color bg;
    Color fg;
    String text;
    IconData ic;

    switch (status.toLowerCase()) {
      case 'published':
        bg = AppColors.successLight;
        fg = AppColors.success;
        text = 'Diterbitkan';
        ic = Icons.check_circle_outline;
        break;
      case 'pending':
        bg = AppColors.warningLight;
        fg = const Color(0xFFB45309);
        text = 'Menunggu Review';
        ic = Icons.access_time;
        break;
      case 'draft':
        bg = AppColors.draftLight;
        fg = AppColors.draft;
        text = 'Draft';
        ic = Icons.edit_note;
        break;
      case 'rejected':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        text = 'Perlu Revisi';
        ic = Icons.cancel_outlined;
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        text = status;
        ic = Icons.label_outline;
    }

    return BadgeChip(
      label: text,
      backgroundColor: bg,
      textColor: fg,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? AppColors.primary
        : (backgroundColor ?? AppColors.primaryLight);
    final effectiveFg = isSelected
        ? Colors.white
        : (textColor ?? AppColors.primary);

    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.primaryLightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: effectiveFg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: effectiveFg,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      );
    }

    return chip;
  }
}
