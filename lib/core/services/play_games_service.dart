// Google Play Games Services bridge service for Flutter

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/play_games_constants.dart';

class PlayGamesService extends ChangeNotifier {
  static final PlayGamesService _instance = PlayGamesService._internal();
  factory PlayGamesService() => _instance;
  PlayGamesService._internal();

  final MethodChannel _channel = const MethodChannel(PlayGamesConstants.channelName);

  bool _isAuthenticated = false;
  String? _playerId;
  String? _displayName;
  String? _iconImageUri;
  bool _isInitializing = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get playerId => _playerId;
  String? get displayName => _displayName;
  String? get iconImageUri => _iconImageUri;
  bool get isInitializing => _isInitializing;

  /// Returns true only on Android mobile where Play Games is supported
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initializes authentication check and silent sign-in
  Future<void> initialize() async {
    if (!isSupported) return;
    _isInitializing = true;
    notifyListeners();

    try {
      // Silent check on startup: NEVER prompt or launch login screens when opening the app
      await checkAuth();
      if (_isAuthenticated) {
        await getPlayerProfile();
      }
    } on MissingPluginException {
      // Running in unit test or mock environment
    } catch (e) {
      debugPrint('PlayGamesService initialize error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  String? _lastError;
  String? get lastError => _lastError;

  /// Interactive or silent sign-in to Google Play Games Services
  Future<bool> signIn() async {
    if (!isSupported) return false;

    try {
      final res = await _channel
          .invokeMethod<Map>('signIn')
          .timeout(const Duration(seconds: 12));
      if (res != null) {
        _isAuthenticated = res['isAuthenticated'] == true;
        _playerId = res['playerId'] as String?;
        _displayName = res['displayName'] as String?;
        _iconImageUri = res['iconImageUri'] as String?;
        _lastError = res['error'] as String?;
        notifyListeners();
        return _isAuthenticated;
      }
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      _lastError = e.message;
      debugPrint('PlayGamesService signIn PlatformException: ${e.message}');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('PlayGamesService signIn error: $e');
    }
    return false;
  }

  /// Verifies whether the player is currently authenticated
  Future<bool> checkAuth() async {
    if (!isSupported) return false;

    try {
      final res = await _channel.invokeMethod<Map>('checkAuth');
      if (res != null) {
        _isAuthenticated = res['isAuthenticated'] == true;
        if (_isAuthenticated && _displayName == null) {
          await getPlayerProfile();
        }
        notifyListeners();
        return _isAuthenticated;
      }
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService checkAuth PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService checkAuth error: $e');
    }
    return false;
  }

  /// Retrieves current player profile details
  Future<void> getPlayerProfile() async {
    if (!isSupported) return;

    try {
      final res = await _channel.invokeMethod<Map>('getPlayerProfile');
      if (res != null) {
        _playerId = res['playerId'] as String?;
        _displayName = res['displayName'] as String?;
        _iconImageUri = res['iconImageUri'] as String?;
        notifyListeners();
      }
    } on MissingPluginException {
      return;
    } catch (e) {
      debugPrint('PlayGamesService getPlayerProfile error: $e');
    }
  }

  /// Submits the high score to the Google Play Games leaderboard
  Future<bool> submitScore(int score, {String? leaderboardId}) async {
    if (!isSupported || score <= 0) return false;

    final targetId = leaderboardId ?? PlayGamesConstants.highScoresLeaderboardId;
    if (targetId.isEmpty || targetId.contains('PLACEHOLDER')) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('submitScore', {
        'leaderboardId': targetId,
        'score': score,
      });
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService submitScore PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService submitScore error: $e');
    }
    return false;
  }

  /// Shows the Google Play Games Leaderboard UI overlay
  Future<bool> showLeaderboard({String? leaderboardId}) async {
    if (!isSupported) return false;

    final targetId = leaderboardId ?? PlayGamesConstants.highScoresLeaderboardId;
    final cleanId = (targetId.isNotEmpty && !targetId.contains('PLACEHOLDER')) ? targetId : null;

    try {
      final args = <String, dynamic>{};
      if (cleanId != null) {
        args['leaderboardId'] = cleanId;
      }
      final success = await _channel.invokeMethod<bool>('showLeaderboard', args);
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService showLeaderboard PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService showLeaderboard error: $e');
    }
    return false;
  }

  /// Shows the Google Play Games Achievements UI overlay
  Future<bool> showAchievements() async {
    if (!isSupported) return false;

    try {
      final success = await _channel.invokeMethod<bool>('showAchievements');
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService showAchievements PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService showAchievements error: $e');
    }
    return false;
  }

  /// Unlocks an achievement in Google Play Games
  Future<bool> unlockAchievement(String achievementId) async {
    if (!isSupported) return false;

    // Resolve mapped ID if an internal key was passed
    final resolvedId = PlayGamesConstants.achievementIdMap[achievementId] ?? achievementId;
    if (resolvedId.isEmpty || resolvedId.contains('PLACEHOLDER')) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('unlockAchievement', {
        'achievementId': resolvedId,
      });
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService unlockAchievement PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService unlockAchievement error: $e');
    }
    return false;
  }

  /// Increments an incremental achievement in Google Play Games
  Future<bool> incrementAchievement(String achievementId, {int steps = 1}) async {
    if (!isSupported || steps <= 0) return false;

    final resolvedId = PlayGamesConstants.achievementIdMap[achievementId] ?? achievementId;
    if (resolvedId.isEmpty || resolvedId.contains('PLACEHOLDER')) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('incrementAchievement', {
        'achievementId': resolvedId,
        'steps': steps,
      });
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlayGamesService incrementAchievement PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('PlayGamesService incrementAchievement error: $e');
    }
    return false;
  }
}
