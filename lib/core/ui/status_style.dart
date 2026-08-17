import 'package:flutter/material.dart';

class StatusStyle {
  static Color colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'upcoming':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.yellow.shade800;
    }
  }
}
