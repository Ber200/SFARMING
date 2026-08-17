import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Semantic status badge pill for admin tables, cards, and list views.
enum AdminStatusType {
  success,
  warning,
  error,
  info,
  neutral,
}

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final AdminStatusType type;
  final IconData? icon;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.type = AdminStatusType.neutral,
    this.icon,
  });

  factory AdminStatusBadge.fromStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approved') ||
        lower.contains('completed') ||
        lower.contains('active') ||
        lower.contains('healthy') ||
        lower.contains('optimal')) {
      return AdminStatusBadge(
        label: status,
        type: AdminStatusType.success,
        icon: Icons.check_circle_rounded,
      );
    }
    if (lower.contains('pending') ||
        lower.contains('warning') ||
        lower.contains('low') ||
        lower.contains('upcoming') ||
        lower.contains('attention')) {
      return AdminStatusBadge(
        label: status,
        type: AdminStatusType.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (lower.contains('cancelled') ||
        lower.contains('critical') ||
        lower.contains('high risk') ||
        lower.contains('inactive') ||
        lower.contains('overdue')) {
      return AdminStatusBadge(
        label: status,
        type: AdminStatusType.error,
        icon: Icons.cancel_rounded,
      );
    }
    return AdminStatusBadge(
      label: status,
      type: AdminStatusType.info,
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor) = switch (type) {
      AdminStatusType.success => (
          Colors.green.shade50,
          AppTheme.adminPrimary,
          Colors.green.shade200,
        ),
      AdminStatusType.warning => (
          Colors.amber.shade50,
          Colors.amber.shade900,
          Colors.amber.shade200,
        ),
      AdminStatusType.error => (
          Colors.red.shade50,
          Colors.red.shade800,
          Colors.red.shade200,
        ),
      AdminStatusType.info => (
          Colors.blue.shade50,
          Colors.blue.shade800,
          Colors.blue.shade200,
        ),
      AdminStatusType.neutral => (
          Colors.grey.shade100,
          Colors.grey.shade800,
          Colors.grey.shade300,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
