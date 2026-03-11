// lib/presentation/widgets/listing/listing_card.dart

import 'package:flutter/material.dart';
import '../common/status_badge.dart';
import '../../../config/theme.dart';
import '../../../domain/models/coffee_listing.dart';

class ListingCard extends StatelessWidget {
  final CoffeeListing listing;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.margin16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                  topRight: Radius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Image.network(
                  listing.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.padding12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.variety,
                          style: AppTheme.heading2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(
                        label: listing.status.name,
                        type: _getStatusType(listing.status.name),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  Text(
                    '${listing.quantity} kg • \$${listing.pricePerKg}/kg',
                    style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  Row(
                    children: [
                      Icon(Icons.terrain, size: AppTheme.iconSizeSmall, color: AppTheme.textSecondary),
                      const SizedBox(width: AppTheme.margin4),
                      Text('${listing.altitude}m', style: AppTheme.caption),
                      const SizedBox(width: AppTheme.margin16),
                      Icon(Icons.star, size: AppTheme.iconSizeSmall, color: Colors.amber),
                      const SizedBox(width: AppTheme.margin4),
                      Text('${listing.qualityScore}/100', style: AppTheme.caption),
                    ],
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: AppTheme.margin12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onEdit != null)
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: AppTheme.iconSizeSmall),
                            label: const Text('Edit'),
                          ),
                        if (onDelete != null)
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete, size: AppTheme.iconSizeSmall),
                            label: const Text('Delete'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusBadgeType _getStatusType(String status) {
    switch (status) {
      case 'active':
        return StatusBadgeType.active;
      case 'sold':
        return StatusBadgeType.success;
      case 'draft':
        return StatusBadgeType.pending;
      case 'expired':
        return StatusBadgeType.error;
      default:
        return StatusBadgeType.neutral;
    }
  }
}
