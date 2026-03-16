// Feature: brewmaster-marketplace
// Search and discovery screen — "Direct Trade Shop" Figma design.
//
// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.7, 4.8, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/models/search_filters.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/profile_avatar_button.dart';
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
  late TextEditingController _searchController;

  String? _selectedVariety;
  String? _selectedMethod;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _minAltitudeController = TextEditingController();
    _maxAltitudeController = TextEditingController();
    context.read<ListingBloc>().add(const ActiveListingsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedVariety = null;
      _selectedMethod = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAltitudeController.clear();
      _maxAltitudeController.clear();
      _showFilters = false;
    });
    context.read<ListingBloc>().add(const ActiveListingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Brew Master',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: const [ProfileAvatarButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Direct Trade\nShop',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore specialty lots directly from their producers.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // ── Search bar ──────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search varieties, origins, or producers',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Advanced Filters button ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.tune, size: 18, color: Colors.white),
                    label: Text(
                      _showFilters
                          ? 'HIDE FILTERS'
                          : 'ADVANCED FILTERS',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // ── Filter Panel ────────────────────────────────────────
                if (_showFilters) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BEAN TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FilterCheckbox(
                          label: 'Artisanal Roasted Beans',
                          value: _selectedVariety == 'roasted',
                          onChanged: (v) => setState(() =>
                              _selectedVariety = v == true ? 'roasted' : null),
                        ),
                        _FilterCheckbox(
                          label: 'Green / Unroasted Lots',
                          value: _selectedVariety == 'green',
                          onChanged: (v) => setState(() =>
                              _selectedVariety = v == true ? 'green' : null),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PROCESSING METHOD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: ['Washed', 'Natural', 'Honey', 'Wet-Hulled']
                              .map((m) => _FilterChip(
                                    label: m,
                                    selected: _selectedMethod ==
                                        m.toLowerCase().replaceAll('-', '_'),
                                    onSelected: (v) => setState(
                                      () => _selectedMethod = v
                                          ? m.toLowerCase().replaceAll('-', '_')
                                          : null,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PRICE RANGE (USD/KG)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactTextField(
                                controller: _minPriceController,
                                hint: 'Min',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CompactTextField(
                                controller: _maxPriceController,
                                hint: 'Max',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text(
                                'CLEAR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'APPLY FILTERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          // ── Listing Results ──────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) {
                if (state is ListingLoading || state is ListingInitial) {
                  return const LoadingIndicator();
                }

                final listings = state is ActiveListingsLoaded
                    ? state.listings
                    : const <CoffeeListing>[];

                if (listings.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No listings found',
                    description: 'Try adjusting your filters',
                    icon: Icons.search_off,
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _ListingCard(
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

// ── Listing Card (Figma style) ─────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final CoffeeListing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lotRating = (listing.qualityScore / 20).clamp(0.0, 5.0);
    final producerInitial = listing.farmerId.isNotEmpty
        ? listing.farmerId[0].toUpperCase()
        : 'F';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with overlays ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  // Image or placeholder
                  listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  // Dark gradient at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Heart icon top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Lot rating bottom-left
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          'Lot rating ${lotRating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Card body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.location.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TRC-${listing.listingId.substring(0, 4).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    listing.variety,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Producer row
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            producerInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Producer',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description (italic quote)
                  if (listing.description.isNotEmpty)
                    Text(
                      '"${listing.description}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Price + acquire button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price / KG',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '\$${listing.pricePerKg.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.add, size: 16,
                            color: Colors.white),
                        label: const Text(
                          'Acquire Lot',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppTheme.inputFillColor,
      child: const Center(
        child: Icon(Icons.coffee, size: 48, color: AppTheme.textHint),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _FilterCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _FilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryDark
              : AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _CompactTextField(
      {required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
        filled: true,
        fillColor: AppTheme.inputFillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
