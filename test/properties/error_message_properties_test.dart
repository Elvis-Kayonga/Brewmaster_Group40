// test/properties/error_message_properties_test.dart
//
// Property-based tests for tasks 29.4/29.5: AppErrorHandler classification
// and the AppError model, using pure Dart (no BuildContext needed).
//
// Developer: Developer 6

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/services/app_error_handler.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppError model (task 29.5)', () {
    test('network error has cloud_off icon', () {
      const err = AppError(
          type: AppErrorType.network, rawMessage: 'network error');
      expect(err.icon.codePoint, isNonZero);
    });

    test('auth error carries the raw message', () {
      const err =
          AppError(type: AppErrorType.auth, rawMessage: 'unauthenticated');
      expect(err.rawMessage, 'unauthenticated');
    });

    test('technicalDetails defaults to null', () {
      const err =
          AppError(type: AppErrorType.unknown, rawMessage: 'oops');
      expect(err.technicalDetails, isNull);
    });

    test('all error types have a non-null icon', () {
      for (final type in AppErrorType.values) {
        final err = AppError(type: type, rawMessage: 'x');
        expect(err.icon, isNotNull);
      }
    });
  });

  group('AppErrorHandler.classify — exceptions (task 29.5)', () {
    test('SocketException is classified as network', () {
      final err =
          AppErrorHandler.classify(const SocketException('no route'));
      expect(err.type, AppErrorType.network);
    });

    test('FormatException is classified as server', () {
      final err = AppErrorHandler.classify(const FormatException('bad json'));
      expect(err.type, AppErrorType.server);
    });

    test('generic Exception falls back to unknown', () {
      final err = AppErrorHandler.classify(Exception('something'));
      expect(err.type, AppErrorType.unknown);
    });
  });

  group('AppErrorHandler.classifyMessage — keyword matching (task 29.5)', () {
    test('network keyword → network type', () {
      expect(AppErrorHandler.classifyMessage('network unavailable').type,
          AppErrorType.network);
    });

    test('offline keyword → network type', () {
      expect(AppErrorHandler.classifyMessage('device is offline').type,
          AppErrorType.network);
    });

    test('internet keyword → network type', () {
      expect(AppErrorHandler.classifyMessage('no internet').type,
          AppErrorType.network);
    });

    test('unauthenticated → auth type', () {
      expect(AppErrorHandler.classifyMessage('unauthenticated').type,
          AppErrorType.auth);
    });

    test('permission-denied → auth type', () {
      expect(
          AppErrorHandler.classifyMessage('permission-denied').type,
          AppErrorType.auth);
    });

    test('permission → permission type', () {
      expect(AppErrorHandler.classifyMessage('permission required').type,
          AppErrorType.permission);
    });

    test('not-found → notFound type', () {
      expect(AppErrorHandler.classifyMessage('not-found').type,
          AppErrorType.notFound);
    });

    test('no document → notFound type', () {
      expect(
          AppErrorHandler.classifyMessage('no document exists').type,
          AppErrorType.notFound);
    });

    test('invalid → validation type', () {
      expect(AppErrorHandler.classifyMessage('invalid email format').type,
          AppErrorType.validation);
    });

    test('server → server type', () {
      expect(AppErrorHandler.classifyMessage('internal server error').type,
          AppErrorType.server);
    });

    test('timeout → server type', () {
      expect(AppErrorHandler.classifyMessage('request timeout').type,
          AppErrorType.server);
    });

    test('unknown message → unknown type', () {
      expect(
          AppErrorHandler.classifyMessage('something completely random').type,
          AppErrorType.unknown);
    });

    test('empty string → unknown type', () {
      expect(AppErrorHandler.classifyMessage('').type,
          AppErrorType.unknown);
    });
  });

  group('AppErrorHandler — raw message preserved (task 29.5)', () {
    test('classified error preserves original message', () {
      const msg = 'network connection lost';
      final err = AppErrorHandler.classifyMessage(msg);
      expect(err.rawMessage, msg);
    });

    test('case-insensitive matching', () {
      expect(AppErrorHandler.classifyMessage('NETWORK ERROR').type,
          AppErrorType.network);
    });

    test('classify(exception) sets rawMessage from toString', () {
      final ex = Exception('my error detail');
      final err = AppErrorHandler.classify(ex);
      expect(err.rawMessage, contains('my error detail'));
    });
  });
}
