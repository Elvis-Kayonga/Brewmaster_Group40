// lib/data/services/app_error_handler.dart
//
// Centralised error classification service.
// Maps raw exceptions and string messages to typed AppError instances
// with user-facing messages resolved from AppLocalizations.
//
// Requirements: 10.4, 10.5
// Developer: Developer 6

import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/localization/app_localizations.dart';

/// Broad error categories used across the app.
enum AppErrorType {
  network,
  server,
  auth,
  permission,
  notFound,
  validation,
  unknown,
}

/// A classified application error.
class AppError {
  final AppErrorType type;

  /// Raw / technical message (not shown directly to users).
  final String rawMessage;

  /// Optional stack trace for logging.
  final String? technicalDetails;

  const AppError({
    required this.type,
    required this.rawMessage,
    this.technicalDetails,
  });

  /// Material icon that represents this error type.
  IconData get icon {
    switch (type) {
      case AppErrorType.network:
        return Icons.cloud_off_outlined;
      case AppErrorType.server:
        return Icons.dns_outlined;
      case AppErrorType.auth:
        return Icons.login_outlined;
      case AppErrorType.permission:
        return Icons.lock_outline;
      case AppErrorType.notFound:
        return Icons.search_off_outlined;
      case AppErrorType.validation:
        return Icons.warning_amber_outlined;
      case AppErrorType.unknown:
        return Icons.error_outline;
    }
  }
}

/// Classifies exceptions and error strings into [AppError] instances and
/// resolves localised messages via [AppLocalizations].
class AppErrorHandler {
  const AppErrorHandler._();

  // ---------------------------------------------------------------------------
  // Classification
  // ---------------------------------------------------------------------------

  /// Classify a raw [exception] into an [AppError].
  static AppError classify(Object exception) {
    if (exception is SocketException || exception is HttpException) {
      return const AppError(
          type: AppErrorType.network, rawMessage: 'network error');
    }
    if (exception is FormatException) {
      return AppError(
        type: AppErrorType.server,
        rawMessage: exception.message,
        technicalDetails: exception.source?.toString(),
      );
    }
    return classifyMessage(exception.toString());
  }

  /// Classify a plain error [message] string into an [AppError].
  static AppError classifyMessage(String message) {
    final lower = message.toLowerCase();

    if (_contains(lower, ['network', 'socket', 'connection', 'internet', 'offline', 'no internet'])) {
      return AppError(type: AppErrorType.network, rawMessage: message);
    }
    if (_contains(lower, [
      'unauthenticated',
      'unauthorized',
      'permission-denied',
      'not-authenticated',
      'sign_in',
      'auth',
    ])) {
      return AppError(type: AppErrorType.auth, rawMessage: message);
    }
    if (_contains(lower, ['permission', 'forbidden', 'access denied'])) {
      return AppError(type: AppErrorType.permission, rawMessage: message);
    }
    if (_contains(lower, ['not-found', 'not found', 'no document', 'does not exist'])) {
      return AppError(type: AppErrorType.notFound, rawMessage: message);
    }
    if (_contains(lower, ['invalid', 'validation', 'required', 'format error'])) {
      return AppError(type: AppErrorType.validation, rawMessage: message);
    }
    if (_contains(lower, ['server', 'internal', '500', 'unavailable', '503', 'timeout'])) {
      return AppError(type: AppErrorType.server, rawMessage: message);
    }
    return AppError(type: AppErrorType.unknown, rawMessage: message);
  }

  // ---------------------------------------------------------------------------
  // Localised message resolution
  // ---------------------------------------------------------------------------

  /// Returns the localised user-facing string for [error] from [context].
  static String localizedMessage(BuildContext context, AppError error) {
    final loc = AppLocalizations.of(context);
    switch (error.type) {
      case AppErrorType.network:
        return loc.errorNetwork;
      case AppErrorType.server:
        return loc.errorServer;
      case AppErrorType.auth:
        return loc.errorAuth;
      case AppErrorType.permission:
        return loc.errorPermission;
      case AppErrorType.notFound:
      case AppErrorType.validation:
      case AppErrorType.unknown:
        return loc.errorUnknown;
    }
  }

  /// Convenience: classify [message] and immediately resolve a localised string.
  static String localizedFromMessage(BuildContext context, String message) =>
      localizedMessage(context, classifyMessage(message));

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _contains(String text, List<String> keywords) =>
      keywords.any(text.contains);
}
