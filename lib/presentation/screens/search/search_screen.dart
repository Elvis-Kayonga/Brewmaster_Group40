// lib/presentation/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/listing/listing_card.dart';
import '../../../config/theme.dart';
import '../../../data/providers/listing_provider.dart';
import '../../../domain/models/search_filters.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minAltitudeController;
  late TextEditingController _maxAltitudeController;

  String? _selectedVariety;
  String? _selectedMethod;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _minAltitudeController = TextEditingController();
    _maxAltitudeController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadActiveListings();
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAltitudeController.dispose();
    _maxAltitudeController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = SearchFilters(
      variety: _selectedVariety,
      processingMethod: _selectedMethod,
      minPrice: _minPriceController.text.isEmpty ? null : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty ? null : double.tryParse(_maxPriceController.text),
      minAltitude: _minAltitudeController.text.isEmpty ? null : double.tryParse(_minAltitudeController.text),
      maxAltitude: _maxAltitudeController.text.isEmpty ? null : double.tryParse(_maxAltitudeController.text),
    );
    context.read<ListingProvider>().searchListings(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedVariety = null;
      _selectedMethod = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAltitudeController.clear();
      _maxAltitudeController.clear();
    });
    context.read<ListingProvider>().loadActiveListings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Listings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.padding16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: _showFilters ? 'Hide Filters' : 'Show Filters',
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        type: ButtonType.outlined,
                      ),
                    ),
                    const SizedBox(width: AppTheme.margin8),
                    Expanded(
                      child: CustomButton(
                        text: 'Clear',
                        onPressed: _clearFilters,
                        type: ButtonType.outlined,
                      ),
                    ),
                  ],
                ),
                if (_showFilters) ...[
                  const SizedBox(height: AppTheme.margin16),
                  CustomTextField(
                    labelText: 'Min Price',
                    controller: _minPriceController,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  CustomTextField(
                    labelText: 'Max Price',
                    controller: _maxPriceController,
                    hintText: '100',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  CustomTextField(
                    labelText: 'Min Altitude',
                    controller: _minAltitudeController,
                    hintText: '800',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.margin8),
                  CustomTextField(
                    labelText: 'Max Altitude',
                    controller: _maxAltitudeController,
                    hintText: '2500',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.margin16),
                  CustomButton(
                    text: 'Apply Filters',
                    onPressed: _applyFilters,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Consumer<ListingProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: LoadingIndicator());
                }

                if (provider.listings.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No listings found',
                    description: 'Try adjusting your filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.padding16),
                  itemCount: provider.listings.length,
                  itemBuilder: (context, index) {
                    final listing = provider.listings[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () {
                        Navigator.pushNamed(context, '/listing-detail', arguments: listing.listingId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
