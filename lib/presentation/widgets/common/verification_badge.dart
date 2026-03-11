// Feature: brewmaster-verification
// Reusable badge showing a user's verification status.
// Shows nothing for unverified users; shows icon+label for other statuses.
//
// Requirements: 7.4, 7.5, 7.6
// Developer: Developer 2

import 'package:flutter/material.dart';
import '../../../domain/models/enums.dart';

class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;

  /// When true, renders a compact icon-only badge (for tight spaces like cards).
  final bool compact;

  const VerificationBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == VerificationStatus.unverified) return const SizedBox.shrink();

    final (icon, color, label) = _props();

    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 16, color: color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _props() {
    switch (status) {
      case VerificationStatus.verified:
        return (Icons.verified, const Color(0xFF388E3C), 'Verified');
      case VerificationStatus.pending:
        return (Icons.hourglass_top, const Color(0xFFF57F17), 'Pending');
      case VerificationStatus.rejected:
        return (Icons.cancel, const Color(0xFFD32F2F), 'Rejected');
      case VerificationStatus.unverified:
        return (Icons.help_outline, Colors.grey, 'Unverified');
    }
  }
}
