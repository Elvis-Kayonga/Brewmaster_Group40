// Feature: brewmaster-marketplace
// Form screen for creating and editing coffee listings.
// Location split into address (human-readable) and lat/lng (for map).
//
// Requirements: 2.1, 2.2, 2.7, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/localization/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/date_picker_widget.dart';

class ListingFormScreen extends StatefulWidget {
  final CoffeeListing? listing;
  /// farmerId of the currently signed-in farmer — required for new listings.
  final String farmerId;

  const ListingFormScreen({super.key, this.listing, this.farmerId = ''});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  late TextEditingController _varietyController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _altitudeController;
  late TextEditingController _qualityScoreController;
  late TextEditingController _descriptionController;
  /// Human-readable address (e.g. "Kigali, Rwanda") — shown on listing cards.
  late TextEditingController _locationAddressController;
  /// Auto-filled from geocoding; stored as "lat,lng" for map pins.
  late TextEditingController _latController;
  late TextEditingController _lngController;

  ProcessingMethod? _selectedMethod;
  DateTime? _harvestDate;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _varietyController = TextEditingController(text: l?.variety ?? '');
    _quantityController =
        TextEditingController(text: l?.quantity.toString() ?? '');
    _priceController =
        TextEditingController(text: l?.pricePerKg.toString() ?? '');
    _altitudeController =
        TextEditingController(text: l?.altitude.toString() ?? '');
    _qualityScoreController =
        TextEditingController(text: l?.qualityScore.toString() ?? '');
    _descriptionController =
        TextEditingController(text: l?.description ?? '');
    _locationAddressController =
        TextEditingController(text: l?.locationAddress ?? '');

    // Pre-populate lat/lng from existing location string if editing
    final coords = _parseCoordsFromLocation(l?.location ?? '');
    _latController = TextEditingController(
        text: coords != null ? coords.$1.toStringAsFixed(6) : '');
    _lngController = TextEditingController(
        text: coords != null ? coords.$2.toStringAsFixed(6) : '');

    _selectedMethod = l?.processingMethod;
    _harvestDate = l?.harvestDate;
  }

  /// Parse a "lat,lng" or JSON location string into (lat, lng). Returns null
  /// if the string isn't recognisable as coordinates.
  (double, double)? _parseCoordsFromLocation(String raw) {
    if (raw.isEmpty) return null;
    // Try comma-separated
    final parts = raw.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) return (lat, lng);
    }
    return null;
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _altitudeController.dispose();
    _qualityScoreController.dispose();
    _descriptionController.dispose();
    _locationAddressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _geocodeLocation() async {
    final address = _locationAddressController.text.trim();
    if (address.isEmpty) return;
    setState(() => _isGeocoding = true);
    try {
      final results = await locationFromAddress(address);
      if (results.isNotEmpty && mounted) {
        final loc = results.first;
        setState(() {
          _latController.text = loc.latitude.toStringAsFixed(6);
          _lngController.text = loc.longitude.toStringAsFixed(6);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).geocodeFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages = images.map((img) => File(img.path)).toList();
    });
  }

  void _submitForm() {
    final address = _locationAddressController.text.trim();
    if (_varietyController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _altitudeController.text.isEmpty ||
        _qualityScoreController.text.isEmpty ||
        _selectedMethod == null ||
        _harvestDate == null ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).fillRequiredFields)),
      );
      return;
    }

    // Build the coordinate string for the map ("lat,lng").
    // If the farmer hasn't geocoded yet, we use the address as a fallback
    // (the map view already handles non-coordinate strings gracefully).
    final lat = _latController.text.trim();
    final lng = _lngController.text.trim();
    final locationCoords =
        lat.isNotEmpty && lng.isNotEmpty ? '$lat,$lng' : address;

    final now = DateTime.now();
    final profileState = context.read<ProfileBloc>().state;
    final farmerName = profileState is ProfileLoaded
        ? profileState.profile.displayName
        : widget.listing?.farmerName;

    final listing = CoffeeListing(
      listingId: widget.listing?.listingId ?? '',
      farmerId: widget.listing?.farmerId ?? widget.farmerId,
      farmerName: farmerName,
      variety: _varietyController.text,
      quantity: double.parse(_quantityController.text),
      pricePerKg: double.parse(_priceController.text),
      processingMethod: _selectedMethod!,
      altitude: double.parse(_altitudeController.text),
      harvestDate: _harvestDate!,
      qualityScore: double.parse(_qualityScoreController.text),
      description: _descriptionController.text,
      images: widget.listing?.images ?? [],
      location: locationCoords,
      locationAddress: address,
      status: widget.listing?.status ?? ListingStatus.active,
      createdAt: widget.listing?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.listing == null) {
      context.read<ListingBloc>().add(ListingCreateRequested(
            listing: listing,
            images: _selectedImages.isNotEmpty ? _selectedImages : null,
          ));
    } else {
      context.read<ListingBloc>().add(ListingUpdateRequested(
            listing: listing,
            newImages: _selectedImages.isNotEmpty ? _selectedImages : null,
          ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.listing != null;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? loc.editListing : loc.createListing),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              labelText: loc.variety,
              controller: _varietyController,
              hintText: 'e.g., Bourbon, Typica',
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: loc.quantityKg,
              controller: _quantityController,
              hintText: 'Enter quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: loc.pricePerKgUsd,
              controller: _priceController,
              hintText: 'Enter price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            SimpleDropdown(
              labelText: 'Processing Method',
              value: _selectedMethod?.name,
              items: ProcessingMethod.values.map((m) => m.name).toList(),
              onChanged: (value) => setState(() {
                _selectedMethod = ProcessingMethod.values
                    .firstWhere((m) => m.name == value);
              }),
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: loc.altitudeM,
              controller: _altitudeController,
              hintText: 'Enter altitude',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            DatePickerWidget(
              labelText: loc.harvestDate,
              selectedDate: _harvestDate,
              onDateChanged: (date) =>
                  setState(() => _harvestDate = date),
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: loc.qualityScore0100,
              controller: _qualityScoreController,
              hintText: 'Enter score',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: loc.description,
              controller: _descriptionController,
              hintText: loc.describeYourCoffee,
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.margin16),

            // ── Location ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: loc.farmLocationAddress,
                    controller: _locationAddressController,
                    hintText: 'e.g., Kigali, Rwanda',
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tooltip(
                    message: loc.geocodeTooltip,
                    child: _isGeocoding
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : IconButton.filled(
                            icon: const Icon(Icons.my_location),
                            onPressed: _geocodeLocation,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Lat/Lng read-only display — auto-filled by geocode button
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: loc.latitude,
                    controller: _latController,
                    hintText: loc.autoFilled,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    labelText: loc.longitude,
                    controller: _lngController,
                    hintText: loc.autoFilled,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.margin16),

            CustomButton(
              text: loc.pickImages,
              onPressed: _pickImages,
              type: ButtonType.outlined,
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.padding8),
                child: Text(
                    '${_selectedImages.length} ${loc.imagesSelected}'),
              ),
            const SizedBox(height: AppTheme.margin24),
            BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) => CustomButton(
                text: isEdit ? loc.updateListing : loc.createListing,
                onPressed: state is ListingLoading ? null : _submitForm,
                isLoading: state is ListingLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
