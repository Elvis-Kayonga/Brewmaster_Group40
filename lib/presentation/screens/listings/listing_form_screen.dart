// lib/presentation/screens/listings/listing_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/date_picker_widget.dart';
import '../../../config/theme.dart';
import '../../../data/providers/listing_provider.dart';
import '../../../domain/models/coffee_listing.dart';

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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  ProcessingMethod? _selectedMethod;
  DateTime? _harvestDate;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _varietyController = TextEditingController(text: widget.listing?.variety ?? '');
    _quantityController = TextEditingController(text: widget.listing?.quantity.toString() ?? '');
    _priceController = TextEditingController(text: widget.listing?.pricePerKg.toString() ?? '');
    _altitudeController = TextEditingController(text: widget.listing?.altitude.toString() ?? '');
    _qualityScoreController = TextEditingController(text: widget.listing?.qualityScore.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.listing?.description ?? '');
    _latitudeController = TextEditingController(text: widget.listing?.location['latitude'].toString() ?? '');
    _longitudeController = TextEditingController(text: widget.listing?.location['longitude'].toString() ?? '');
    _selectedMethod = widget.listing?.processingMethod;
    _harvestDate = widget.listing?.harvestDate;
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _altitudeController.dispose();
    _qualityScoreController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages = images.map((img) => File(img.path)).toList();
    });
  }

  Future<void> _submitForm() async {
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
      location: {
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
      },
      status: widget.listing?.status ?? ListingStatus.draft,
      createdAt: widget.listing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<ListingProvider>();
    if (widget.listing == null) {
      await provider.createListing(listing, _selectedImages.isNotEmpty ? _selectedImages : null);
    } else {
      await provider.updateListing(listing, _selectedImages.isNotEmpty ? _selectedImages : null);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listing == null ? 'Create Listing' : 'Edit Listing')),
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
              onChanged: (value) {
                setState(() {
                  _selectedMethod = ProcessingMethod.values.firstWhere((m) => m.name == value);
                });
              },
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
              onDateChanged: (date) {
                setState(() {
                  _harvestDate = date;
                });
              },
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
              labelText: 'Latitude',
              controller: _latitudeController,
              hintText: 'Enter latitude',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomTextField(
              labelText: 'Longitude',
              controller: _longitudeController,
              hintText: 'Enter longitude',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.margin16),
            CustomButton(
              text: 'Pick Images',
              onPressed: _pickImages,
              type: ButtonType.outlined,
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.padding16),
                child: Text('${_selectedImages.length} images selected'),
              ),
            const SizedBox(height: AppTheme.margin24),
            Consumer<ListingProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: widget.listing == null ? 'Create Listing' : 'Update Listing',
                  onPressed: provider.isLoading ? null : _submitForm,
                  isLoading: provider.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
