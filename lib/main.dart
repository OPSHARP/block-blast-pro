// Application Entrypoint for Block Blast Pro

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/update/in_app_update_service.dart';
import 'data/repositories/prefs_save_repository.dart';
import 'game/game_coordinator.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Strip all debug print statements in release production builds
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }

    // Disable remote font fetching over network to guarantee 100% offline crash immunity
    try {
      GoogleFonts.config.allowRuntimeFetching = false;
    } catch (_) {}

    // Global uncaught error interceptors to prevent crashes
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('BlockBlastPro FlutterError: ${details.exception}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('BlockBlastPro Uncaught Async Error: $error\n$stack');
      return true; // Prevents crash
    };

    // Lock orientation to portrait for optimal mobile gaming experience
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}

    // Configure edge-to-edge system UI and overlay styles
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    } catch (_) {}

    // Unlock highest refresh rate safely post-frame (non-blocking, activity fully attached)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterDisplayMode.setHighRefreshRate().catchError((_) {});
      } catch (_) {}
    });

    // Initialize persistence repository & coordinator safely
    final saveRepository = PrefsSaveRepository();
    final coordinator = GameCoordinator(saveRepository: saveRepository);
    try {
      await coordinator.initialize();
    } catch (e) {
      debugPrint('GameCoordinator initialize non-fatal: $e');
    }

    // Initialize In-App Update Service (passed to app for snackbar integration)
    final updateService = InAppUpdateService();

    runApp(BlockBlastProApp(
      coordinator: coordinator,
      updateService: updateService,
    ));
  }, (error, stack) {
    debugPrint('BlockBlastPro runZonedGuarded intercepted error: $error\n$stack');
  });
}

class BlockBlastProApp extends StatelessWidget {
  final GameCoordinator coordinator;
  final InAppUpdateService updateService;

  const BlockBlastProApp({
    super.key,
    required this.coordinator,
    required this.updateService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Blast Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F0F8),
        fontFamilyFallback: const ['sans-serif', 'Roboto'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.light,
        ),
      ),
      home: HomeScreen(
        coordinator: coordinator,
        updateService: updateService,
      ),
    );
  }
}

