// Feature: brewmaster-marketplace
// Screen showing the farmer's own listings with create/edit/delete actions.
//
// Requirements: 2.1, 2.2, 2.3, 2.4, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/sync_status_indicator.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/listing/listing_card.dart';
import 'listing_detail_screen.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final String farmerId;

  const MyListingsScreen({super.key, required this.farmerId});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<ListingBloc>()
        .add(FarmerListingsLoadRequested(widget.farmerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        elevation: 0,
        actions: const [SyncStatusIndicator()],
      ),
      body: BlocConsumer<ListingBloc, ListingState>(
        listener: (context, state) {
          if (state is ListingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context
                .read<ListingBloc>()
                .add(FarmerListingsLoadRequested(widget.farmerId));
          }
          if (state is ListingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ListingLoading || state is ListingInitial) {
            return const LoadingIndicator();
          }

          if (state is ListingFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<ListingBloc>()
                  .add(FarmerListingsLoadRequested(widget.farmerId)),
            );
          }

          final listings =
              state is FarmerListingsLoaded ? state.listings : const [];

          if (listings.isEmpty) {
            return EmptyStateWidget(
              title: 'No listings yet',
              description: 'Create your first coffee listing',
              icon: Icons.local_cafe_outlined,
              actionText: 'Create Listing',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ListingBloc>(),
                    child: const ListingFormScreen(),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListingCard(
                listing: listing,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ListingBloc>(),
                      child: ListingDetailScreen(
                          listingId: listing.listingId),
                    ),
                  ),
                ),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ListingBloc>(),
                      child: ListingFormScreen(listing: listing),
                    ),
                  ),
                ),
                onDelete: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Listing'),
                    content: const Text(
                        'Are you sure you want to delete this listing?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<ListingBloc>().add(
                              ListingDeleteRequested(listing.listingId));
                          Navigator.pop(context);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ListingBloc>(),
              child: const ListingFormScreen(),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
