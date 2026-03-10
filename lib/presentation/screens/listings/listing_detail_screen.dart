// lib/presentation/screens/listings/listing_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../../config/theme.dart';
import '../../../data/providers/listing_provider.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadListing(widget.listingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: Consumer<ListingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (provider.error != null) {
            return ErrorStateWidget(
              title: 'Error',
              message: provider.error ?? 'Error loading listing',
              onRetry: () => provider.loadListing(widget.listingId),
            );
          }

          final listing = provider.currentListing;
          if (listing == null) {
            return const Center(child: Text('Listing not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listing.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppTheme.padding8),
                          child: ClipRRect(
                            borderRadius: AppTheme.borderRadiusMediumAll,
                            child: Image.network(
                              listing.images[index],
                              fit: BoxFit.cover,
                              width: 200,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AppTheme.margin16),
                Text(listing.variety, style: AppTheme.heading1),
                const SizedBox(height: AppTheme.margin8),
                Text('${listing.quantity} kg available', style: AppTheme.body),
                const SizedBox(height: AppTheme.margin16),
                _buildDetailRow('Price per kg', '\$${listing.pricePerKg}'),
                _buildDetailRow('Processing Method', listing.processingMethod.name),
                _buildDetailRow('Altitude', '${listing.altitude}m'),
                _buildDetailRow('Harvest Date', listing.harvestDate.toString().split(' ')[0]),
                _buildDetailRow('Quality Score', '${listing.qualityScore}/100'),
                _buildDetailRow('Status', listing.status.name),
                const SizedBox(height: AppTheme.margin16),
                Text('Description', style: AppTheme.heading2),
                const SizedBox(height: AppTheme.margin8),
                Text(listing.description, style: AppTheme.body),
                const SizedBox(height: AppTheme.margin24),
                CustomButton(
                  text: 'Contact Farmer',
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.padding8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body.copyWith(color: AppTheme.textSecondary)),
          Text(value, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
