// Feature: brewmaster-marketplace
// Form screen for creating and editing coffee listings.
// location field uses "lat,lng" string format matching the canonical model.
//
// Requirements: 2.1, 2.2, 2.7, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/date_picker_widget.dart';

class ListingFormScreen extends StatefulWidget {
  final CoffeeListing? listing;

  const ListingFormScreen({super.key, this.listing});

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
  late TextEditingController _locationController;

  ProcessingMethod? _selectedMethod;
  DateTime? _harvestDate;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

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
    _locationController =
        TextEditingController(text: l?.location ?? '');
    _selectedMethod = l?.processingMethod;
    _harvestDate = l?.harvestDate;
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _altitudeController.dispose();
    _qualityScoreController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages = images.map((img) => File(img.path)).toList();
    });
  }

  void _submitForm() {
    if (_varietyController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _altitudeController.text.isEmpty ||
        _qualityScoreController.text.isEmpty ||
        _selectedMethod == null ||
        _harvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final now = DateTime.now();
    final listing = CoffeeListing(
      listingId: widget.listing?.listingId ?? '',
      farmerId: widget.listing?.farmerId ?? '',
      variety: _varietyController.text,
      quantity: double.parse(_quantityController.text),
      pricePerKg: double.parse(_priceController.text),
      processingMethod: _selectedMethod!,
      altitude: double.parse(_altitudeController.text),
      harvestDate: _harvestDate!,
      qualityScore: double.parse(_qualityScoreController.text),
      description: _descriptionController.text,
      images: widget.listing?.images ?? [],
      location: _locationController.text,
      status: widget.listing?.status ?? ListingStatus.draft,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Listing' : 'Create Listing'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              labelText: 'Variety',
              controller: _varietyController,
              hintText: 'e.g., Bourbon, Typica',
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Quantity (kg)',
              controller: _quantityController,
              hintText: 'Enter quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Price per kg (USD)',
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
              labelText: 'Altitude (m)',
              controller: _altitudeController,
              hintText: 'Enter altitude',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            DatePickerWidget(
              labelText: 'Harvest Date',
              selectedDate: _harvestDate,
              onDateChanged: (date) =>
                  setState(() => _harvestDate = date),
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Quality Score (0-100)',
              controller: _qualityScoreController,
              hintText: 'Enter score',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Description',
              controller: _descriptionController,
              hintText: 'Describe your coffee',
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Location (lat,lng)',
              controller: _locationController,
              hintText: 'e.g., -1.9441,29.8739',
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomButton(
              text: 'Pick Images',
              onPressed: _pickImages,
              type: ButtonType.outlined,
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.padding8),
                child: Text(
                    '${_selectedImages.length} image(s) selected'),
              ),
            const SizedBox(height: AppTheme.margin24),
            BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) => CustomButton(
                text: isEdit ? 'Update Listing' : 'Create Listing',
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
