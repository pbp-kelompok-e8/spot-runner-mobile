import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';

Future<T?> safeApiCall<T>({
  required BuildContext context,
  required Future<T> Function() call,
  required String errorMessage,
  required VoidCallback onRetry,
  bool silent = false,
}) async {
  try {
    return await call();
  } catch (e) {
    if (!context.mounted) return null;

    if (!silent) {
      context.read<ConnectivityProvider>().setError(
        errorMessage,
        onRetry,
      );
    }

    return null;
  }
}
