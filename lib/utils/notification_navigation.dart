import '../core/routes/app_routes.dart';
import '../models/notification_model.dart';

/// Centralizes "tap a notification → where does it go" so the notification
/// center modal and the push/local tap handlers behave identically.
///
/// When a notification carries a [NotificationModel.relatedId] pointing at a
/// record (e.g. a scheduled treatment), the target screen is opened with the
/// record id so it can select/highlight the exact record (nav.md §13, §27).
/// Missing records degrade gracefully to the plain screen.
class NotificationNavigation {
  /// Builds the route arguments that select/highlight the related record.
  ///
  /// Only routes that support record-level deep linking accept arguments;
  /// anything else opens normally with no arguments.
  static Object? argumentsFor(NotificationModel notification) {
    final relatedId = notification.relatedId;
    if (relatedId == null || relatedId.isEmpty) return null;
    if (notification.actionRoute == AppRoutes.treatmentCalendar) {
      return relatedId;
    }
    return null;
  }

  /// Navigates to the notification's destination, deep-linking to the related
  /// record when one exists. Silently no-ops if the navigator is not mounted
  /// yet (e.g. cold start) so the tap is never a crash.
  static Future<void> open(NotificationModel notification) async {
    final route = notification.actionRoute;
    if (route == null || route.isEmpty) return;
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.pushNamed(route, arguments: argumentsFor(notification));
  }
}
