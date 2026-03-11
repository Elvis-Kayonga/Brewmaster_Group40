// Feature: brewmaster-marketplace
// Screen displaying full details of a single coffee listing.
//
// Requirements: 2.1, 4.6, 8.1, 8.3, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

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
    context.read<ListingBloc>().add(ListingLoadRequested(widget.listingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details'), elevation: 0),
      body: BlocBuilder<ListingBloc, ListingState>(
        builder: (context, state) {
          if (state is ListingLoading || state is ListingInitial) {
            return const LoadingIndicator();
          }

          if (state is ListingFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<ListingBloc>()
                  .add(ListingLoadRequested(widget.listingId)),
            );
          }

          if (state is! ListingDetailLoaded) {
            return const SizedBox.shrink();
          }

          final listing = state.listing;

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
                      itemBuilder: (context, index) => Padding(
                        padding:
                            const EdgeInsets.only(right: AppTheme.padding8),
                        child: ClipRRect(
                          borderRadius: AppTheme.borderRadiusMediumAll,
                          child: Image.network(
                            listing.images[index],
                            fit: BoxFit.cover,
                            width: 200,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.margin16),
                Text(listing.variety, style: AppTheme.heading1),
                const SizedBox(height: AppTheme.margin8),
                Text('${listing.quantity} kg available',
                    style: AppTheme.body),
                const SizedBox(height: AppTheme.margin16),
                _DetailRow('Price per kg', '\$${listing.pricePerKg}'),
                _DetailRow('Processing Method',
                    listing.processingMethod.name),
                _DetailRow('Altitude', '${listing.altitude}m'),
                _DetailRow('Harvest Date',
                    listing.harvestDate.toIso8601String().split('T')[0]),
                _DetailRow(
                    'Quality Score', '${listing.qualityScore}/100'),
                _DetailRow('Status', listing.status.name),
                _DetailRow('Location', listing.location),
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.padding8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.body
                  .copyWith(color: AppTheme.textSecondary)),
          Text(value,
              style:
                  AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
