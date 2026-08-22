import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;

  const StatusBadgeWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        break;
      case 'completed':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        break;
      case 'arrived':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        break;
      default:
        bgColor = context.theme.dividerColor.withValues(alpha: 0.1);
        textColor = context.theme.hintColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.tr,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}