import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Logs the exact Firebase plugin / code / message (permission, CORS, package
/// mismatch signals often surface here) without changing the user-facing map.
void logFirebaseException(
  FirebaseException e, {
  String context = 'Firebase',
  StackTrace? stackTrace,
}) {
  debugPrint(
    '[$context] FirebaseException '
    'plugin=${e.plugin} code=${e.code} message=${e.message}',
  );
  if (stackTrace != null) {
    debugPrint('[$context] stack:\n$stackTrace');
  }
}

/// Maps [FirebaseException] codes to short, user-facing messages.
String mapFirebaseExceptionMessage(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return 'You do not have permission to perform this action.';
    case 'unavailable':
    case 'network-request-failed':
      return 'Network unavailable. Check your connection and try again.';
    case 'deadline-exceeded':
    case 'timeout':
      return 'Request timed out. Please try again.';
    case 'object-not-found':
      return 'The requested file was not found.';
    case 'unauthorized':
      return 'Upload was not authorized. Please sign in again.';
    case 'canceled':
      return 'The operation was canceled.';
    case 'not-found':
      return 'The requested data was not found.';
    case 'already-exists':
      return 'This item already exists.';
    case 'resource-exhausted':
      return 'Too many requests. Please wait and try again.';
    case 'unauthenticated':
      return 'Please sign in again to continue.';
    default:
      return e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : 'Something went wrong. Please try again.';
  }
}

/// Runs a Firebase/IO action and maps failures to [Exception] with a
/// user-friendly message so callers never see raw platform errors.
Future<T> guardFirebase<T>(
  Future<T> Function() action, {
  String context = 'Firebase',
}) async {
  try {
    return await action();
  } on FirebaseException catch (e, st) {
    logFirebaseException(e, context: context, stackTrace: st);
    throw Exception(
      '${mapFirebaseExceptionMessage(e)} '
      '[plugin=${e.plugin} code=${e.code}]',
    );
  } on TimeoutException {
    debugPrint('[$context] TimeoutException');
    throw Exception('Request timed out. Check your connection and try again.');
  } on SocketException catch (e) {
    debugPrint('[$context] SocketException: $e');
    throw Exception('No internet connection. Check your network and try again.');
  }
}

/// Ensures Firestore/Storage stream errors become friendly [Exception]s
/// instead of uncaught async stream failures.
Stream<T> guardFirebaseStream<T>(
  Stream<T> stream, {
  String context = 'FirebaseStream',
}) {
  return stream.handleError((Object error, StackTrace stackTrace) {
    if (error is FirebaseException) {
      logFirebaseException(error, context: context, stackTrace: stackTrace);
      throw Exception(
        '${mapFirebaseExceptionMessage(error)} '
        '[plugin=${error.plugin} code=${error.code}]',
      );
    }
    if (error is TimeoutException) {
      debugPrint('[$context] TimeoutException');
      throw Exception(
        'Request timed out. Check your connection and try again.',
      );
    }
    if (error is SocketException) {
      debugPrint('[$context] SocketException: $error');
      throw Exception(
        'No internet connection. Check your network and try again.',
      );
    }
    debugPrint('[$context] stream error: $error\n$stackTrace');
    throw error;
  });
}
