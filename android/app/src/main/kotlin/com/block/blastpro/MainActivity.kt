package com.block.blastpro

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.WindowManager
import com.google.android.gms.games.AuthenticationResult
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.block.blastpro/play_games"
        private const val RC_LEADERBOARD_UI = 9002
        private const val RC_ACHIEVEMENTS_UI = 9003
    }

    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            // Google Play Games Services v2 initialization
            PlayGamesSdk.initialize(this)
        } catch (t: Throwable) {
            Log.w(TAG, "PlayGamesSdk initialization non-fatal: ${t.message}")
        }
        try {
            enableHighestRefreshRate()
        } catch (t: Throwable) {
            Log.w(TAG, "enableHighestRefreshRate non-fatal: ${t.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                handlePlayGamesCall(call, result)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun safeSuccess(result: MethodChannel.Result, value: Any?) {
        try {
            result.success(value)
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to send success result to Flutter: ${t.message}")
        }
    }

    private fun safeError(result: MethodChannel.Result, errorCode: String, errorMessage: String?, errorDetails: Any?) {
        try {
            result.error(errorCode, errorMessage, errorDetails)
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to send error result to Flutter: ${t.message}")
        }
    }

    private fun handlePlayGamesCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "signIn" -> {
                    val gamesSignInClient = PlayGames.getGamesSignInClient(this)
                    gamesSignInClient.signIn().addOnCompleteListener { task ->
                        if (isFinishing || isDestroyed) return@addOnCompleteListener
                        try {
                            if (task.isSuccessful) {
                                val authResult: AuthenticationResult = task.result
                                val isAuthenticated = authResult.isAuthenticated
                                if (isAuthenticated) {
                                    fetchPlayerProfile(result)
                                } else {
                                    safeSuccess(result, mapOf("isAuthenticated" to false))
                                }
                            } else {
                                safeSuccess(result, mapOf(
                                    "isAuthenticated" to false,
                                    "error" to (task.exception?.message ?: "Sign-in failed")
                                ))
                            }
                        } catch (t: Throwable) {
                            Log.w(TAG, "PlayGames signIn callback non-fatal: ${t.message}")
                            safeSuccess(result, mapOf("isAuthenticated" to false, "error" to t.message))
                        }
                    }
                }
                "checkAuth" -> {
                    val gamesSignInClient = PlayGames.getGamesSignInClient(this)
                    gamesSignInClient.isAuthenticated.addOnCompleteListener { task ->
                        if (isFinishing || isDestroyed) return@addOnCompleteListener
                        try {
                            if (task.isSuccessful) {
                                val authResult: AuthenticationResult = task.result
                                safeSuccess(result, mapOf("isAuthenticated" to authResult.isAuthenticated))
                            } else {
                                safeSuccess(result, mapOf("isAuthenticated" to false))
                            }
                        } catch (t: Throwable) {
                            Log.w(TAG, "PlayGames checkAuth callback non-fatal: ${t.message}")
                            safeSuccess(result, mapOf("isAuthenticated" to false))
                        }
                    }
                }
                "getPlayerProfile" -> {
                    fetchPlayerProfile(result)
                }
                "submitScore" -> {
                    val leaderboardId = call.argument<String>("leaderboardId")
                    val score = call.argument<Number>("score")?.toLong() ?: 0L
                    if (leaderboardId.isNullOrEmpty()) {
                        safeError(result, "INVALID_ARGS", "Leaderboard ID is required", null)
                        return
                    }
                    val leaderboardsClient = PlayGames.getLeaderboardsClient(this)
                    leaderboardsClient.submitScore(leaderboardId, score)
                    safeSuccess(result, true)
                }
                "showLeaderboard" -> {
                    val leaderboardId = call.argument<String>("leaderboardId")
                    val leaderboardsClient = PlayGames.getLeaderboardsClient(this)
                    val intentTask = if (!leaderboardId.isNullOrEmpty()) {
                        leaderboardsClient.getLeaderboardIntent(leaderboardId)
                    } else {
                        leaderboardsClient.allLeaderboardsIntent
                    }
                    intentTask.addOnSuccessListener { intent ->
                        if (isFinishing || isDestroyed) return@addOnSuccessListener
                        try {
                            startActivityForResult(intent, RC_LEADERBOARD_UI)
                            safeSuccess(result, true)
                        } catch (t: Throwable) {
                            safeError(result, "ACTIVITY_NOT_FOUND", t.message, null)
                        }
                    }.addOnFailureListener { e ->
                        if (isFinishing || isDestroyed) return@addOnFailureListener
                        safeError(result, "LEADERBOARD_ERROR", e.message, null)
                    }
                }
                "showAchievements" -> {
                    val achievementsClient = PlayGames.getAchievementsClient(this)
                    achievementsClient.achievementsIntent.addOnSuccessListener { intent ->
                        if (isFinishing || isDestroyed) return@addOnSuccessListener
                        try {
                            startActivityForResult(intent, RC_ACHIEVEMENTS_UI)
                            safeSuccess(result, true)
                        } catch (t: Throwable) {
                            safeError(result, "ACTIVITY_NOT_FOUND", t.message, null)
                        }
                    }.addOnFailureListener { e ->
                        if (isFinishing || isDestroyed) return@addOnFailureListener
                        safeError(result, "ACHIEVEMENTS_ERROR", e.message, null)
                    }
                }
                "unlockAchievement" -> {
                    val achievementId = call.argument<String>("achievementId")
                    if (achievementId.isNullOrEmpty()) {
                        safeError(result, "INVALID_ARGS", "Achievement ID is required", null)
                        return
                    }
                    val achievementsClient = PlayGames.getAchievementsClient(this)
                    achievementsClient.unlock(achievementId)
                    safeSuccess(result, true)
                }
                "incrementAchievement" -> {
                    val achievementId = call.argument<String>("achievementId")
                    val steps = call.argument<Int>("steps") ?: 1
                    if (achievementId.isNullOrEmpty()) {
                        safeError(result, "INVALID_ARGS", "Achievement ID is required", null)
                        return
                    }
                    val achievementsClient = PlayGames.getAchievementsClient(this)
                    achievementsClient.increment(achievementId, steps)
                    safeSuccess(result, true)
                }
                "openPlayStore" -> {
                    val targetPackage = call.argument<String>("packageName") ?: packageName
                    try {
                        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$targetPackage")).apply {
                            setPackage("com.android.vending")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        }
                        startActivity(marketIntent)
                        safeSuccess(result, true)
                    } catch (_: Throwable) {
                        try {
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$targetPackage")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(webIntent)
                            safeSuccess(result, true)
                        } catch (t: Throwable) {
                            safeError(result, "PLAY_STORE_ERROR", t.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            safeError(result, "PLAY_GAMES_EXCEPTION", t.message, null)
        }
    }

    private fun fetchPlayerProfile(result: MethodChannel.Result) {
        try {
            val playersClient = PlayGames.getPlayersClient(this)
            playersClient.currentPlayer.addOnCompleteListener { playerTask ->
                if (isFinishing || isDestroyed) return@addOnCompleteListener
                try {
                    if (playerTask.isSuccessful) {
                        val player = playerTask.result
                        safeSuccess(result, mapOf(
                            "isAuthenticated" to true,
                            "playerId" to player.playerId,
                            "displayName" to player.displayName,
                            "iconImageUri" to player.iconImageUri?.toString(),
                            "hiResImageUri" to player.hiResImageUri?.toString()
                        ))
                    } else {
                        safeSuccess(result, mapOf("isAuthenticated" to true))
                    }
                } catch (t: Throwable) {
                    safeSuccess(result, mapOf("isAuthenticated" to true, "error" to t.message))
                }
            }
        } catch (t: Throwable) {
            safeSuccess(result, mapOf("isAuthenticated" to true, "error" to t.message))
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        try {
            enableHighestRefreshRate()
        } catch (_: Throwable) {
        }
    }

    private fun enableHighestRefreshRate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val disp = display
                if (disp != null) {
                    var maxRate = 60.0f
                    var targetMode: Display.Mode? = null
                    for (mode in disp.supportedModes) {
                        if (mode.refreshRate >= maxRate) {
                            maxRate = mode.refreshRate
                            targetMode = mode
                        }
                    }
                    if (targetMode != null) {
                        val params = window.attributes
                        params.preferredDisplayModeId = targetMode.modeId
                        window.attributes = params
                    }
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val windowManager = getSystemService(WINDOW_SERVICE) as? WindowManager
                @Suppress("DEPRECATION")
                val disp = windowManager?.defaultDisplay
                if (disp != null) {
                    var maxRate = 60.0f
                    var targetMode: Display.Mode? = null
                    for (mode in disp.supportedModes) {
                        if (mode.refreshRate >= maxRate) {
                            maxRate = mode.refreshRate
                            targetMode = mode
                        }
                    }
                    if (targetMode != null) {
                        val params = window.attributes
                        params.preferredDisplayModeId = targetMode.modeId
                        window.attributes = params
                    }
                }
            }
        } catch (_: Throwable) {
            // Graceful fallback to default refresh rate if device display manager restricts changes
        }
    }
}

