import 'package:flutter/material.dart';
import 'app_swal_dialog.dart';

class AppDeleteConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String itemDetails,
  }) async {
    return AppSwalDialog.showDeleteConfirmation(
      context,
      title: title,
      itemDetails: itemDetails,
    );
  }
}
