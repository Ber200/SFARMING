import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auth_provider.dart';

/// A slim amber banner displayed at the top of every farmer screen when the
/// device is offline or the user is in offline mode.
///
/// Usage — wrap the Scaffold body:
/// ```dart
/// body: Column(
///   children: [
///     const OfflineBanner(),
///     Expanded(child: yourContent),
///   ],
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityProvider, AuthProvider>(
      builder: (context, connectivity, auth, _) {
        final showBanner = !connectivity.isOnline || auth.isOfflineMode;
        if (!showBanner) return const SizedBox.shrink();

        final label = auth.isOfflineMode
            ? 'Offline Mode — some features are unavailable'
            : 'No internet connection — working offline';

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFFFF3CD),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: Color(0xFF856404)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856404),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
