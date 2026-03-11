import 'package:flutter/material.dart';

import '../../domain/models/buyer_dashboard.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/farmer_dashboard.dart';
import '../services/dashboard_service.dart';

/// State management for the farmer and buyer dashboard screens.
///
/// Fetches aggregated metrics via [DashboardService], handles loading / error
/// states, and caches the last-loaded data so the dashboard remains visible
/// while offline (Requirement 11.5, Property 48).
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 16.1 (Clean Architecture),
///               16.2 (Provider state management)
/// Developer: Developer 5
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? service})
      : _service = service ?? DashboardService();

  final DashboardService _service;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  FarmerDashboard _farmerDashboard = FarmerDashboard.empty();
  BuyerDashboard _buyerDashboard = BuyerDashboard.empty();
  bool _isLoading = false;
  String? _error;
  UserRole? _currentRole;
  String? _currentUserId;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  FarmerDashboard get farmerDashboard => _farmerDashboard;
  BuyerDashboard get buyerDashboard => _buyerDashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get currentRole => _currentRole;

  // ---------------------------------------------------------------------------
  // Methods
  // ---------------------------------------------------------------------------

  /// Loads dashboard data for the given [userId] and [role].
  ///
  /// Property 46: metrics accurately reflect the user's Firestore data.
  Future<void> loadDashboard(String userId, UserRole role) async {
    _currentUserId = userId;
    _currentRole = role;
    _setLoading(true);
    _error = null;

    try {
      if (role == UserRole.farmer) {
        _farmerDashboard = await _service.getFarmerDashboard(userId);
      } else {
        _buyerDashboard = await _service.getBuyerDashboard(userId);
      }
    } catch (e) {
      _error = 'Could not load dashboard. '
          'Showing last available data.';
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the dashboard with the most recent data.
  Future<void> refresh() async {
    if (_currentUserId != null && _currentRole != null) {
      await loadDashboard(_currentUserId!, _currentRole!);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
