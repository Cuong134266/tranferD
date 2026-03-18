import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ViewAllButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const ViewAllButton({
    super.key,
    this.text = 'Tất cả',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppTheme.viewAllText),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
