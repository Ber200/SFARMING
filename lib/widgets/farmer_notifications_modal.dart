import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_navigation.dart';

/// The farmer's Notification Center.
///
/// Reads persisted records from [NotificationProvider] (real-time synced),
/// groups them by Today / Yesterday / Earlier, highlights unread items and
/// routes taps to the relevant screen.
class FarmerNotificationsModal extends StatelessWidget {
  const FarmerNotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FarmerNotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: AppTheme.brandPrimary),
                const SizedBox(width: 8),
                Text(
                  'Notification Center',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () => provider.markAllRead(),
                    child: const Text('Mark all as read'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Weather advisories, treatment reminders and tips will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = provider.notifications
        .where((n) => !n.createdAt.isBefore(today))
        .toList();
    final yesterdayItems = provider.notifications
        .where((n) => !n.createdAt.isBefore(yesterday) && n.createdAt.isBefore(today))
        .toList();
    final earlierItems = provider.notifications
        .where((n) => n.createdAt.isBefore(yesterday))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (todayItems.isNotEmpty) ...[
          _sectionHeader(context, 'Today'),
          ...todayItems.map((n) => _NotificationTile(notification: n)),
        ],
        if (yesterdayItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader(context, 'Yesterday'),
          ...yesterdayItems.map((n) => _NotificationTile(notification: n)),
        ],
        if (earlierItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader(context, 'Earlier'),
          ...earlierItems.map((n) => _NotificationTile(notification: n)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.type);
    final provider = Provider.of<NotificationProvider>(context);
    final unread = !notification.read;

    return Material(
      color: unread ? AppTheme.brandPrimary.withValues(alpha: 0.06) : Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          provider.markRead(notification.id);
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationNavigation.open(notification);
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: style.color.withValues(alpha: 0.15),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: unread ? Colors.black87 : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _styleFor(NotificationType type) {
    switch (type) {
      case NotificationType.treatmentReminder:
        return (icon: Icons.medical_services_rounded, color: const Color(0xFFE53935));
      case NotificationType.fertilizerReminder:
        return (icon: Icons.grass_rounded, color: const Color(0xFF43A047));
      case NotificationType.farmActivity:
        return (icon: Icons.agriculture_rounded, color: AppTheme.brandPrimary);
      case NotificationType.weatherAdvisory:
        return (icon: Icons.warning_amber_rounded, color: const Color(0xFFFB8C00));
      case NotificationType.weatherUpdate:
        return (icon: Icons.cloud_rounded, color: const Color(0xFF1E88E5));
      case NotificationType.tip:
        return (icon: Icons.lightbulb_rounded, color: const Color(0xFF00897B));
      case NotificationType.adminAnnouncement:
        return (icon: Icons.campaign_rounded, color: const Color(0xFF8E24AA));
    }
  }

  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      final diff = now.difference(time);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return 'Today';
    }
    if (date == yesterday) return 'Yesterday';
    return '${_monthAbbr(time.month)} ${time.day}, ${time.year}';
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
