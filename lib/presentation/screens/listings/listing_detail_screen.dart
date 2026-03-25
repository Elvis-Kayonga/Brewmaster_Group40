// Feature: brewmaster-marketplace
// Screen displaying full details of a single coffee listing — "Heritage Ledger" design.
//
// Requirements: 2.1, 4.6, 8.1, 8.3, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../config/theme.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../messaging/chat_screen.dart';

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

  /// Parse location stored as JSON {"latitude": x, "longitude": y}.
  /// Falls back gracefully if the string is not valid JSON.
  LatLng? _parseLocation(String locationString) {
    if (locationString.isEmpty) return null;
    try {
      final map = jsonDecode(locationString) as Map<String, dynamic>;
      final lat = (map['latitude'] as num?)?.toDouble();
      final lng = (map['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    } catch (_) {
      // Not JSON — map won't be shown
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: AppTheme.primaryDark),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<MessagingBloc, MessagingState>(
        listenWhen: (_, s) => s is ConversationReady || s is MessagingFailure,
        listener: (context, msgState) {
          if (msgState is ConversationReady) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: msgState.conversation),
              ),
            );
          } else if (msgState is MessagingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msgState.message)),
            );
          }
        },
        builder: (context, msgState) => BlocBuilder<ListingBloc, ListingState>(
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
            final year = listing.harvestDate.year;
            final mapLocation = _parseLocation(listing.location);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero image with overlay ─────────────────────────
                  Stack(
                    children: [
                      listing.images.isNotEmpty
                          ? Image.network(
                              listing.images.first,
                              height: 320,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 24,
                        right: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COFFEE PROFILE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              listing.variety,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Established c. $year',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Processing station ──────────────────────
                        const Text(
                          'PROCESSING STATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          listing.processingMethod.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          listing.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Specifications ──────────────────────────
                        const Text(
                          'SPECIFICATIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          items: [
                            _DetailItem('Altitude', '${listing.altitude} m'),
                            _DetailItem('Processing', listing.processingMethod.name),
                            _DetailItem('Harvest Year', '$year'),
                            _DetailItem('Quality Score', '${listing.qualityScore}/100'),
                            _DetailItem('Available', '${listing.quantity} kg'),
                            _DetailItem('Price / kg', '\$${listing.pricePerKg.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Farm location map ───────────────────────
                        if (mapLocation != null) ...[
                          const Text(
                            'FARM LOCATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 250,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: mapLocation,
                                  initialZoom: 13.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.brewmaster.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: mapLocation,
                                        width: 60,
                                        height: 60,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: AppTheme.primaryColor,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // ── Contact button ──────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: msgState is MessagingLoading
                                ? null
                                : () {
                                    final currentUid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    if (listing.farmerId == currentUid) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'This is your own listing.')),
                                      );
                                      return;
                                    }
                                    context.read<MessagingBloc>().add(
                                        StartConversationRequested(
                                            listing.farmerId));
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: msgState is MessagingLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'CONTACT FARMER',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 320,
      width: double.infinity,
      color: AppTheme.primaryDark,
      child: const Center(
        child: Icon(Icons.coffee, size: 64, color: Colors.white30),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}

class _DetailCard extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}
