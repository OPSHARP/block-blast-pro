// Procedural ASMR Sound & Tactile Engine for Block Blast Pro
// Generates copyright-free, mathematical tactile audio samples at runtime

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';
import '../../domain/models/block_weight.dart';

enum AsmrIntensity {
  full,
  balanced,
  reduced,
}

enum HapticIntensity {
  off,
  subtle,
  crisp,
  heavy,
}

class AsmrAudioEngine {
  static final AsmrAudioEngine _instance = AsmrAudioEngine._internal();
  static AsmrAudioEngine get instance => _instance;
  factory AsmrAudioEngine({bool enableAudio = true}) {
    _instance.enableAudio = enableAudio;
    return _instance;
  }
  AsmrAudioEngine._internal();

  final Map<String, Uint8List> _wavCache = {};
  final List<AudioPlayer> _playerPool = [];
  int _playerIndex = 0;
  static const int _poolSize = 3;

  bool enableAudio = true;
  bool isMuted = false;
  double masterVolume = 0.8;
  double sfxVolume = 1.0;
  AsmrIntensity intensity = AsmrIntensity.balanced;
  bool isHapticsEnabled = true;
  HapticIntensity hapticIntensity = HapticIntensity.crisp;

  void initialize() {
    if (!enableAudio) return;
    if (_playerPool.isEmpty) {
      for (int i = 0; i < _poolSize; i++) {
        try {
          final player = AudioPlayer();
          player.setReleaseMode(ReleaseMode.stop);
          _playerPool.add(player);
        } catch (e) {
          debugPrint('ASMR Audio player init notice: $e');
        }
      }
    }
  }

  void dispose() {
    for (final player in _playerPool) {
      try {
        player.dispose();
      } catch (_) {}
    }
    _playerPool.clear();
    _wavCache.clear();
  }

  AudioPlayer? _getNextPlayer() {
    if (_playerPool.isEmpty) initialize();
    if (_playerPool.isEmpty) return null;
    final player = _playerPool[_playerIndex];
    _playerIndex = (_playerIndex + 1) % _playerPool.length;
    return player;
  }

  Future<void> _playWav(Uint8List wavBytes, {double volumeMultiplier = 1.0}) async {
    if (isMuted) return;
    try {
      final player = _getNextPlayer();
      if (player == null) return;
      final effectiveVolume = (masterVolume * sfxVolume * volumeMultiplier).clamp(0.0, 1.0);
      await player.setVolume(effectiveVolume);
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('ASMR Audio playback notice: $e');
    }
  }

  // --- HAPTIC INTEGRATION ---
  void triggerHaptic(HapticType type) {
    if (!isHapticsEnabled || kIsWeb || hapticIntensity == HapticIntensity.off) return;
    try {
      if (hapticIntensity == HapticIntensity.subtle) {
        HapticFeedback.selectionClick();
        return;
      }
      if (hapticIntensity == HapticIntensity.heavy) {
        HapticFeedback.heavyImpact();
        return;
      }
      switch (type) {
        case HapticType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {}
  }

  // --- SOUND ACTIONS ---

  void playPickup() {
    triggerHaptic(HapticType.selection);
    final bytes = _getOrCreateWav('pickup', () => _generateTone(
      startFreq: 320,
      endFreq: 480,
      durationMs: 70,
      volume: 0.35,
      type: WaveType.sine,
    ));
    _playWav(bytes, volumeMultiplier: 0.4);
  }

  void playSnap() {
    triggerHaptic(HapticType.light);
    final bytes = _getOrCreateWav('snap', () => _generateTone(
      startFreq: 600,
      endFreq: 750,
      durationMs: 50,
      volume: 0.45,
      type: WaveType.triangle,
    ));
    _playWav(bytes, volumeMultiplier: 0.5);
  }

  void playPlacement({
    required BlockWeightClass weightClass,
    required ThemeSoundProfile soundProfile,
  }) {
    switch (weightClass) {
      case BlockWeightClass.light:
        triggerHaptic(HapticType.light);
        break;
      case BlockWeightClass.normal:
        triggerHaptic(HapticType.medium);
        break;
      case BlockWeightClass.heavy:
      case BlockWeightClass.ultra:
        triggerHaptic(HapticType.heavy);
        break;
    }

    final key = 'place_${weightClass.name}_${soundProfile.name}';
    final bytes = _getOrCreateWav(key, () {
      double baseFreq = 220;
      switch (soundProfile) {
        case ThemeSoundProfile.crystal:
          baseFreq = 523.25; // C5 crystalline
          break;
        case ThemeSoundProfile.neon:
          baseFreq = 330.0; // E4 electronic
          break;
        case ThemeSoundProfile.ocean:
          baseFreq = 261.63; // C4 watery
          break;
        case ThemeSoundProfile.paper:
          baseFreq = 440.0; // A4 crisp tap
          break;
        case ThemeSoundProfile.zen:
          baseFreq = 164.81; // E3 deep stone
          break;
        case ThemeSoundProfile.aurora:
          baseFreq = 392.0; // G4 ethereal
          break;
        case ThemeSoundProfile.gold:
          baseFreq = 587.33; // D5 metallic gold chime
          break;
        case ThemeSoundProfile.magma:
          baseFreq = 130.81; // C3 subterranean rumble
          break;
      }

      // Modify by weight
      final freq = baseFreq / (weightClass.weight >= 2.0 ? 1.5 : 1.0);
      return _generateTactileThud(
        baseFreq: freq,
        durationMs: weightClass.settlementSpeedMs,
        weight: weightClass.weight,
      );
    });

    _playWav(bytes, volumeMultiplier: (0.4 + weightClass.impactStrength * 0.4));
  }

  void playClear({int linesCount = 1, required int comboCount}) {
    playBrickBlast(linesCount: linesCount, comboCount: comboCount);
  }

  /// Procedural royalty-free brick break blast sound effect with musical chord progression
  /// Combines crunchy brick-shatter transient + deep bass blast thump + ascending combo chord arpeggio
  void playBrickBlast({int linesCount = 1, required int comboCount}) {
    triggerHaptic(linesCount > 1 || comboCount >= 4 ? HapticType.heavy : HapticType.medium);

    // Pentatonic scale based on combo count (C4, D4, E4, G4, A4, C5, D5, E5, G5...)
    final pentatonicPitches = [
      261.63, // C4
      293.66, // D4
      329.63, // E4
      392.00, // G4
      440.00, // A4
      523.25, // C5
      587.33, // D5
      659.25, // E5
      783.99, // G5
      880.00, // A5
      1046.50 // C6
    ];

    final pitchIndex = (comboCount - 1).clamp(0, pentatonicPitches.length - 1);
    final rootFreq = pentatonicPitches[pitchIndex];

    final key = 'brick_blast_${linesCount}_${pitchIndex}_c$comboCount';
    final bytes = _getOrCreateWav(key, () {
      return _generateBrickBlastAudio(
        rootFreq: rootFreq,
        linesCount: linesCount,
        durationMs: 280 + (linesCount * 50) + (comboCount >= 3 ? 80 : 0),
        comboCount: comboCount,
      );
    });

    _playWav(bytes, volumeMultiplier: (0.75 + min(comboCount * 0.08, 0.45)));
  }

  void playGridShift() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('grid_shift', () => _generateTone(
      startFreq: 180,
      endFreq: 90,
      durationMs: 280,
      volume: 0.6,
      type: WaveType.sine,
    ));
    _playWav(bytes, volumeMultiplier: 0.7);
  }

  void playGameOver() {
    final bytes = _getOrCreateWav('game_over', () => _generateTone(
      startFreq: 220,
      endFreq: 110,
      durationMs: 400,
      volume: 0.5,
      type: WaveType.sine,
    ));
    _playWav(bytes, volumeMultiplier: 0.6);
  }

  void playAchievement() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('achievement', () => _generateArpeggio(
      frequencies: [440, 554.37, 659.25, 880], // A Major arpeggio
      noteDurationMs: 80,
    ));
    _playWav(bytes, volumeMultiplier: 0.75);
  }

  void playRotate() {
    triggerHaptic(HapticType.light);
    final bytes = _getOrCreateWav('rotate_click', () => _generateTone(
      startFreq: 520,
      endFreq: 980,
      durationMs: 65,
      volume: 0.45,
      type: WaveType.triangle,
    ));
    _playWav(bytes, volumeMultiplier: 0.55);
  }

  void playIceCrack() {
    triggerHaptic(HapticType.medium);
    final bytes = _getOrCreateWav('ice_crack', () => _generateIceCrackAudio());
    _playWav(bytes, volumeMultiplier: 0.65);
  }

  void playIceShatter() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('ice_shatter', () => _generateIceShatterAudio());
    _playWav(bytes, volumeMultiplier: 0.8);
  }

  void playLightningZap() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('lightning_zap', () => _generateZapAudio());
    _playWav(bytes, volumeMultiplier: 0.85);
  }

  void playCoinCollect() {
    triggerHaptic(HapticType.light);
    final bytes = _getOrCreateWav('coin_ping', () => _generateCoinAudio());
    _playWav(bytes, volumeMultiplier: 0.75);
  }

  void playUndo() {
    triggerHaptic(HapticType.medium);
    final bytes = _getOrCreateWav('undo_whoosh', () => _generateSweepAudio(reverse: true));
    _playWav(bytes, volumeMultiplier: 0.65);
  }

  void playColorMagnet() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('magnet_sweep', () => _generateSweepAudio(reverse: false));
    _playWav(bytes, volumeMultiplier: 0.8);
  }

  /// Plays a low-frequency double-thump heartbeat when board is near full capacity
  void playDangerHeartbeat({double urgency = 1.0}) {
    triggerHaptic(urgency > 1.2 ? HapticType.heavy : HapticType.medium);
    final key = 'heartbeat_${(urgency * 10).round()}';
    final bytes = _getOrCreateWav(key, () => _generateHeartbeatAudio(urgency: urgency));
    _playWav(bytes, volumeMultiplier: (0.55 * urgency).clamp(0.4, 0.9));
  }

  /// Plays an elastic tactile drop thud for block placement squash-and-stretch
  void playSquashImpact() {
    triggerHaptic(HapticType.light);
    final bytes = _getOrCreateWav('squash_impact', () => _generateTone(
      startFreq: 260,
      endFreq: 140,
      durationMs: 80,
      volume: 0.45,
      type: WaveType.sine,
    ));
    _playWav(bytes, volumeMultiplier: 0.5);
  }

  /// Procedural deep-bass kinetic explosion sound for TNT blocks and bomb defusal
  void playExplosion() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('explosion', () => _generateExplosionAudio());
    _playWav(bytes, volumeMultiplier: 0.95);
  }

  /// Procedural bubbly cartoon pop sound for tactile button clicks & card interactions
  void playPixarPop({double pitch = 1.0}) {
    triggerHaptic(HapticType.selection);
    final key = 'pixar_pop_${(pitch * 10).round()}';
    final bytes = _getOrCreateWav(key, () => _generatePixarPop(pitch: pitch));
    _playWav(bytes, volumeMultiplier: 0.6);
  }

  /// Procedural squishy spring cartoon boing sound for block bounces and hero character taps
  void playPixarBoing() {
    triggerHaptic(HapticType.light);
    final bytes = _getOrCreateWav('pixar_boing', () => _generatePixarBoing());
    _playWav(bytes, volumeMultiplier: 0.7);
  }

  /// Procedural bright twinkling star arpeggio for rewards, achievements, and milestone unlocks
  void playPixarSparkle() {
    triggerHaptic(HapticType.medium);
    final bytes = _getOrCreateWav('pixar_sparkle', () => _generatePixarSparkle());
    _playWav(bytes, volumeMultiplier: 0.75);
  }

  /// Procedural joyful multi-pitch fanfare for high scores and victory
  void playPixarCheer() {
    triggerHaptic(HapticType.heavy);
    final bytes = _getOrCreateWav('pixar_cheer', () => _generatePixarCheer());
    _playWav(bytes, volumeMultiplier: 0.85);
  }

  static Uint8List _generateExplosionAudio() {
    const int sampleRate = 22050;
    const int durationMs = 380;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);
    final rng = Random(77);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 130.0 * (1.0 - t * 0.75); // Sub-bass pitch sweep down
      phase += 2 * pi * freq / sampleRate;

      final noise = (rng.nextDouble() * 2.0 - 1.0);
      final envelope = exp(-3.8 * t);
      final sample = (sin(phase) * 0.55 + noise * 0.45) * envelope;
      samples[i] = sample.clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generatePixarPop({double pitch = 1.0}) {
    const int sampleRate = 22050;
    const int durationMs = 55;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    double phase = 0.0;
    final startF = 720.0 * pitch;
    final endF = 260.0 * pitch;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = startF + (endF - startF) * pow(t, 0.7);
      phase += 2 * pi * freq / sampleRate;

      final envelope = sin(t * pi * 0.5) * exp(-5.0 * t);
      samples[i] = (sin(phase) * envelope).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generatePixarBoing() {
    const int sampleRate = 22050;
    const int durationMs = 190;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final wobble = sin(24 * pi * t) * 40.0;
      final freq = 180.0 + 340.0 * t + wobble;
      phase += 2 * pi * freq / sampleRate;

      final envelope = (1.0 - t * 0.8) * exp(-2.2 * t);
      samples[i] = (sin(phase) * envelope).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generatePixarSparkle() {
    const int sampleRate = 22050;
    const int durationMs = 320;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    final notes = [784.0, 987.0, 1175.0, 1568.0, 1975.0];
    final noteSamples = numSamples ~/ notes.length;

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      double phase = 0.0;
      final start = n * noteSamples;
      final end = min((n + 2) * noteSamples, numSamples);

      for (int i = start; i < end; i++) {
        final localT = (i - start) / (end - start);
        phase += 2 * pi * freq / sampleRate;
        final env = exp(-4.0 * localT);
        final val = (sin(phase) + 0.3 * sin(phase * 2)) * env * 0.4;
        samples[i] = (samples[i] + val).clamp(-1.0, 1.0);
      }
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generatePixarCheer() {
    const int sampleRate = 22050;
    const int durationMs = 450;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    final chord = [523.25, 659.25, 783.99, 1046.50];

    for (int c = 0; c < chord.length; c++) {
      final freq = chord[c];
      double phase = 0.0;
      final start = (c * (numSamples * 0.12)).round();

      for (int i = start; i < numSamples; i++) {
        final t = (i - start) / (numSamples - start);
        phase += 2 * pi * freq / sampleRate;
        final env = (1.0 - t) * exp(-1.8 * t);
        final val = sin(phase) * env * 0.32;
        samples[i] = (samples[i] + val).clamp(-1.0, 1.0);
      }
    }
    return encodeWav(samples, sampleRate);
  }

  // --- PROCEDURAL AUDIO GENERATION HELPERS ---

  Uint8List _getOrCreateWav(String key, Uint8List Function() generator) {
    if (_wavCache.containsKey(key)) {
      return _wavCache[key]!;
    }
    final wav = generator();
    _wavCache[key] = wav;
    return wav;
  }

  static Uint8List _generateTone({
    required double startFreq,
    required double endFreq,
    required int durationMs,
    required double volume,
    required WaveType type,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples; // 0.0 -> 1.0
      final currentFreq = startFreq + (endFreq - startFreq) * t;
      phase += 2 * pi * currentFreq / sampleRate;

      // Exponential decay envelope
      final envelope = (1.0 - t) * exp(-2.0 * t) * volume;

      double sampleVal = 0.0;
      switch (type) {
        case WaveType.sine:
          sampleVal = sin(phase);
          break;
        case WaveType.triangle:
          sampleVal = (2.0 / pi) * asin(sin(phase));
          break;
      }
      samples[i] = (sampleVal * envelope).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateTactileThud({
    required double baseFreq,
    required int durationMs,
    required double weight,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    double phase = 0.0;
    final decayRate = 3.5 / weight; // Heavier blocks decay slower

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = baseFreq * (1.0 - 0.3 * t);
      phase += 2 * pi * freq / sampleRate;

      // Punchy tactile impulse envelope
      final envelope = exp(-decayRate * t * 4.0);
      final val = sin(phase) * 0.75 + sin(phase * 2) * 0.25;
      samples[i] = (val * envelope).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateBrickBlastAudio({
    required double rootFreq,
    required int linesCount,
    required int durationMs,
    int comboCount = 1,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);
    final rng = Random(1337 + linesCount);

    final isMultiLine = linesCount > 1;
    final f1 = rootFreq;
    final f2 = rootFreq * 1.2599; // +Major 3rd
    final f3 = rootFreq * 1.4983; // +Fifth
    final f4 = rootFreq * 1.8877; // +Major 7th
    final f5 = rootFreq * 2.0;    // +Octave (God Mode)

    double pBass = 0.0;
    double p1 = 0.0, p2 = 0.0, p3 = 0.0, p4 = 0.0, p5 = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples; // 0.0 -> 1.0

      // 1. Heavy Punch Sub-Bass Blast Transient (140Hz down to 45Hz)
      final bassFreq = 140.0 - (95.0 * min(t * 3.0, 1.0));
      pBass += 2 * pi * bassFreq / sampleRate;
      final bassEnvelope = exp(-7.0 * t);
      final bassThump = sin(pBass) * bassEnvelope * (comboCount >= 5 ? 0.85 : 0.7);

      // 2. Crunchy Brick Shatter Noise Transient (tactile fracture ASMR)
      double crunch = 0.0;
      if (t < 0.25) {
        final crunchEnv = exp(-16.0 * t);
        final noise = (rng.nextDouble() * 2.0 - 1.0);
        crunch = noise * crunchEnv * 0.45;
      }

      // 3. Resonant Harmonic Musical Chime Ring (Staggered arpeggio for high combos)
      p1 += 2 * pi * f1 / sampleRate;
      p2 += 2 * pi * f2 / sampleRate;
      p3 += 2 * pi * f3 / sampleRate;
      p4 += 2 * pi * f4 / sampleRate;
      p5 += 2 * pi * f5 / sampleRate;

      final chimeEnv1 = exp(-3.2 * t);
      // Delayed attack for second, third, fourth notes of chord arpeggio
      final chimeEnv2 = t > 0.06 ? exp(-3.2 * (t - 0.06)) : 0.0;
      final chimeEnv3 = t > 0.12 ? exp(-3.2 * (t - 0.12)) : 0.0;
      final chimeEnv4 = t > 0.18 ? exp(-3.2 * (t - 0.18)) : 0.0;
      final chimeEnv5 = t > 0.24 ? exp(-3.2 * (t - 0.24)) : 0.0;

      double chime = sin(p1) * 0.45 * chimeEnv1;
      if (comboCount >= 2) chime += sin(p2) * 0.35 * chimeEnv2;
      if (comboCount >= 3) chime += sin(p3) * 0.30 * chimeEnv3;
      if (comboCount >= 4) chime += sin(p4) * 0.25 * chimeEnv4;
      if (comboCount >= 5) chime += sin(p5) * 0.35 * chimeEnv5;

      // Combine layers for deep tactile blast impact
      double sample = bassThump + crunch + chime * 0.7;
      if (isMultiLine) {
        sample *= 1.25;
      }

      samples[i] = sample.clamp(-1.0, 1.0);
    }

    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateHeartbeatAudio({double urgency = 1.0}) {
    const int sampleRate = 22050;
    const int durationMs = 380;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    final f1 = 65.0 * urgency;
    final f2 = 55.0 * urgency;
    final dubStart = (sampleRate * 0.14).round();

    double p1 = 0.0, p2 = 0.0;
    for (int i = 0; i < numSamples; i++) {
      double sample = 0.0;
      if (i < dubStart) {
        final t = i / dubStart;
        p1 += 2 * pi * f1 / sampleRate;
        final env = sin(t * pi) * exp(-2.5 * t);
        sample += sin(p1) * env * 0.9;
      } else {
        final t = (i - dubStart) / (numSamples - dubStart);
        p2 += 2 * pi * f2 / sampleRate;
        final env = sin(t * pi) * exp(-3.0 * t);
        sample += sin(p2) * env * 0.7;
      }
      samples[i] = sample.clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  @visibleForTesting
  static Uint8List generateChord({
    required double rootFreq,
    required bool isMultiLine,
    required int durationMs,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    // Major 3rd and 5th intervals
    final f1 = rootFreq;
    final f2 = rootFreq * 1.2599; // +Major 3rd
    final f3 = rootFreq * 1.4983; // +Fifth
    final f4 = rootFreq * 2.0;    // +Octave if multiline

    double p1 = 0.0, p2 = 0.0, p3 = 0.0, p4 = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      p1 += 2 * pi * f1 / sampleRate;
      p2 += 2 * pi * f2 / sampleRate;
      p3 += 2 * pi * f3 / sampleRate;
      if (isMultiLine) p4 += 2 * pi * f4 / sampleRate;

      // Soft bell-like exponential decay
      final envelope = exp(-3.0 * t);
      double mix = sin(p1) * 0.5 + sin(p2) * 0.3 + sin(p3) * 0.2;
      if (isMultiLine) mix = mix * 0.8 + sin(p4) * 0.2;

      samples[i] = (mix * envelope).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateArpeggio({
    required List<double> frequencies,
    required int noteDurationMs,
  }) {
    const int sampleRate = 22050;
    final int totalSamples = (sampleRate * ((frequencies.length * noteDurationMs) / 1000.0)).round();
    final samples = Float32List(totalSamples);
    final int samplesPerNote = (sampleRate * (noteDurationMs / 1000.0)).round();

    for (int noteIdx = 0; noteIdx < frequencies.length; noteIdx++) {
      final freq = frequencies[noteIdx];
      double phase = 0.0;
      final startOffset = noteIdx * samplesPerNote;

      for (int i = 0; i < samplesPerNote; i++) {
        final globalIdx = startOffset + i;
        if (globalIdx >= totalSamples) break;
        final t = i / samplesPerNote;
        phase += 2 * pi * freq / sampleRate;
        final env = exp(-2.5 * t) * 0.7;
        samples[globalIdx] = (sin(phase) * env).clamp(-1.0, 1.0);
      }
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateIceCrackAudio() {
    const int sampleRate = 22050;
    const int durationMs = 85;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);
    final rng = Random(42);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 2200.0 - (400.0 * t);
      phase += 2 * pi * freq / sampleRate;

      final noise = (rng.nextDouble() * 2.0 - 1.0);
      final env = exp(-14.0 * t);
      final sample = (sin(phase) * 0.45 + noise * 0.55) * env;
      samples[i] = sample.clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateIceShatterAudio() {
    const int sampleRate = 22050;
    const int durationMs = 220;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);
    final rng = Random(84);

    double p1 = 0.0, p2 = 0.0, p3 = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      p1 += 2 * pi * 1760.0 / sampleRate;
      p2 += 2 * pi * 2640.0 / sampleRate;
      p3 += 2 * pi * 3520.0 / sampleRate;

      final chime = (sin(p1) * 0.4 + sin(p2) * 0.3 + sin(p3) * 0.3);
      final noise = (rng.nextDouble() * 2.0 - 1.0) * (t < 0.3 ? (1.0 - t * 3.3) : 0.0);
      final env = exp(-4.5 * t);
      final sample = (chime * 0.65 + noise * 0.35) * env;
      samples[i] = sample.clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateZapAudio() {
    const int sampleRate = 22050;
    const int durationMs = 140;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);
    final rng = Random(99);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final jitter = (rng.nextDouble() * 160.0 - 80.0);
      final freq = (340.0 + jitter).clamp(100.0, 1200.0);
      phase += 2 * pi * freq / sampleRate;

      final wave = (sin(phase) > 0 ? 0.7 : -0.7); // Square wave buzz
      final env = exp(-6.0 * t);
      samples[i] = (wave * env).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateCoinAudio() {
    const int sampleRate = 22050;
    const int durationMs = 200;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    double p1 = 0.0, p2 = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      p1 += 2 * pi * 1318.51 / sampleRate; // E6
      p2 += 2 * pi * 2093.00 / sampleRate; // C7
      final env = exp(-4.0 * t);
      final sample = (sin(p1) * 0.6 + sin(p2) * 0.4) * env;
      samples[i] = sample.clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  static Uint8List _generateSweepAudio({required bool reverse}) {
    const int sampleRate = 22050;
    const int durationMs = 220;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final samples = Float32List(numSamples);

    final startFreq = reverse ? 880.0 : 220.0;
    final endFreq = reverse ? 220.0 : 880.0;

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = startFreq + (endFreq - startFreq) * t;
      phase += 2 * pi * freq / sampleRate;
      final env = sin(pi * t) * 0.75;
      samples[i] = (sin(phase) * env).clamp(-1.0, 1.0);
    }
    return encodeWav(samples, sampleRate);
  }

  // Encode Float32 PCM samples into standard 16-bit Mono WAV format
  @visibleForTesting
  static Uint8List encodeWav(Float32List samples, int sampleRate) {
    final int byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;

    final bytes = ByteData(44 + dataSize);

    // RIFF Chunk
    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize, Endian.little);
    bytes.setUint8(8, 0x57);  // 'W'
    bytes.setUint8(9, 0x41);  // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    bytes.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    bytes.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, 2, Endian.little);  // BlockAlign (NumChannels * BitsPerSample/8)
    bytes.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    // Write 16-bit PCM samples
    int offset = 44;
    for (int i = 0; i < samples.length; i++) {
      final int val = (samples[i] * 32767.0).round().clamp(-32768, 32767);
      bytes.setInt16(offset, val, Endian.little);
      offset += 2;
    }

    return bytes.buffer.asUint8List();
  }
}

enum HapticType {
  light,
  medium,
  heavy,
  selection,
}

enum WaveType {
  sine,
  triangle,
}
