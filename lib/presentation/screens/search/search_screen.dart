// Feature: brewmaster-marketplace
// Search and discovery screen with filters, using BLoC for state management.
//
// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.7, 4.8, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/search_filters.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/listing/listing_card.dart';
import '../../widgets/common/sync_status_indicator.dart';
import '../listings/listing_detail_screen.dart';

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
    context.read<ListingBloc>().add(const ActiveListingsLoadRequested());
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
      method: _selectedMethod,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
      minAltitude: _minAltitudeController.text.isEmpty
          ? null
          : double.tryParse(_minAltitudeController.text),
      maxAltitude: _maxAltitudeController.text.isEmpty
          ? null
          : double.tryParse(_maxAltitudeController.text),
    );
    context.read<ListingBloc>().add(ListingsSearchRequested(filters));
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
    context.read<ListingBloc>().add(const ActiveListingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Listings'),
        elevation: 0,
        actions: const [SyncStatusIndicator()],
      ),
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
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
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
            child: BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) {
                if (state is ListingLoading || state is ListingInitial) {
                  return const LoadingIndicator();
                }

                final listings = state is ActiveListingsLoaded
                    ? state.listings
                    : const [];

                if (listings.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No listings found',
                    description: 'Try adjusting your filters',
                    icon: Icons.search_off,
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
