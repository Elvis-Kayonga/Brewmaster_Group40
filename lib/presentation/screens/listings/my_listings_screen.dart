// lib/presentation/screens/listings/my_listings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/listing/listing_card.dart';
import '../../../config/theme.dart';
import '../../../data/providers/listing_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadFarmerListings(widget.farmerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: Consumer<ListingProvider>(
        builder: (context, provider, _) {
          if (provider.myListings.isEmpty) {
            return EmptyStateWidget(
              title: 'No listings yet',
              description: 'Create your first coffee listing',
              actionText: 'Create Listing',
              onAction: () {
                Navigator.pushNamed(context, '/listing-form');
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding16),
            itemCount: provider.myListings.length,
            itemBuilder: (context, index) {
              final listing = provider.myListings[index];
              return ListingCard(
                listing: listing,
                onTap: () {
                  Navigator.pushNamed(context, '/listing-detail', arguments: listing.listingId);
                },
                onEdit: () {
                  Navigator.pushNamed(context, '/listing-form', arguments: listing);
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Listing'),
                      content: const Text('Are you sure you want to delete this listing?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.deleteListing(listing.listingId);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/listing-form');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
