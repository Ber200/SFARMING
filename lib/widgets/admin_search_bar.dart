import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Unified Search & Filter bar for admin management views.
class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? filterWidget;

  const AdminSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.filterWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppTheme.adminTextSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppTheme.adminTextPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 14, color: AppTheme.adminTextSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.adminTextSecondary),
              onPressed: () {
                controller.clear();
                onChanged?.call('');
                onClear?.call();
              },
            ),
          if (filterWidget != null) ...[
            const SizedBox(width: 12),
            Container(
              height: 24,
              width: 1,
              color: AppTheme.adminBorder,
            ),
            const SizedBox(width: 12),
            filterWidget!,
          ],
        ],
      ),
    );
  }
}
