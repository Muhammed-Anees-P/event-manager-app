import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLoadingOverlay {
  /// Displays a non-dismissible loading overlay dialog while executing [asyncTask].
  /// Automatically pops the overlay when [asyncTask] completes or throws an error.
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() asyncTask,
    String message = 'Processing...',
  }) async {
    bool isPopped = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      isPopped = true;
    });

    try {
      final result = await asyncTask();
      if (!isPopped && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return result;
    } catch (e) {
      if (!isPopped && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      rethrow;
    }
  }
}
