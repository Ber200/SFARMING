import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Page not found',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'The route you requested does not exist.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.splash,
                  (route) => false,
                ),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
