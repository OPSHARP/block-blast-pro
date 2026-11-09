// Google Play In-App Updates Service (Flexible update flow)
// Compliant with Android Play Core In-App Updates
// Shows a dismissible snackbar when a flexible update has been downloaded

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService extends ChangeNotifier {
  bool _isUpdateAvailable = false;
  bool _isUpdateDownloaded = false;
  bool _isChecking = false;

  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isUpdateDownloaded => _isUpdateDownloaded;
  bool get isChecking => _isChecking;

  /// Checks for a flexible update and starts background download if available.
  /// After download completes, notifies listeners so the UI can show a restart prompt.
  Future<void> checkForUpdate({
    Function()? onUpdateDownloaded,
  }) async {
    // Only available on Android native builds (Play Store environment)
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      _isChecking = true;
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        _isUpdateAvailable = true;
        notifyListeners();

        // Perform flexible background update if supported
        if (info.flexibleUpdateAllowed) {
          debugPrint('InAppUpdateService: Starting flexible update download...');
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            _isUpdateDownloaded = true;
            notifyListeners();
            onUpdateDownloaded?.call();
          }
        }
      }
    } catch (e) {
      // Expected in debug / side-loaded builds not installed from Play Store
      debugPrint('InAppUpdateService check notice: $e');
    } finally {
      _isChecking = false;
      try {
        notifyListeners();
      } catch (_) {}
    }
  }

  /// Completes the flexible update and restarts the app with the new version.
  Future<void> completeUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('InAppUpdateService completeFlexibleUpdate error: $e');
    }
  }

  /// Shows a Material 3 snackbar prompting the user to restart and apply the update.
  /// Call this from any screen after receiving the [isUpdateDownloaded] notification.
  void showUpdateSnackbar(BuildContext context) {
    if (!_isUpdateDownloaded) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update downloaded! Restart to apply.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'RESTART',
          textColor: const Color(0xFF38BDF8),
          onPressed: () => completeUpdate(),
        ),
      ),
    );
  }
}
