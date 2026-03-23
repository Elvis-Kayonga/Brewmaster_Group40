// lib/presentation/screens/listings/listing_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  LatLng? _parseLocation(String locationString) {
    try {
      final locationMap = jsonDecode(locationString) as Map<String, dynamic>;
      final lat = (locationMap['latitude'] as num?)?.toDouble();
      final lng = (locationMap['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      debugPrint('Error parsing location: $e');
    }
    return null;
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

          final mapLocation = listing.location.isNotEmpty ? _parseLocation(listing.location) : null;

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
                if (mapLocation != null) ...[
                  Text('Farm Location', style: AppTheme.heading2),
                  const SizedBox(height: AppTheme.margin8),
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusMediumAll,
                    child: SizedBox(
                      height: 250,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: mapLocation,
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.brewmaster.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: mapLocation,
                                width: 80,
                                height: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppTheme.primaryColor,
                                      size: 40,
                                    ),
                                    Text(
                                      'Farm',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  Text(
                    'Latitude: ${mapLocation.latitude.toStringAsFixed(4)}, Longitude: ${mapLocation.longitude.toStringAsFixed(4)}',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: AppTheme.margin24),
                ],
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
