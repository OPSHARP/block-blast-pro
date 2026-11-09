import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';

void main() {
  group('AsmrAudioEngine WAV Synthesis', () {
    test('encodeWav outputs valid RIFF/WAVE format with 44-byte header', () {
      final sampleRate = 22050;
      final samples = Float32List(100);
      for (int i = 0; i < samples.length; i++) {
        samples[i] = 0.5;
      }

      final wav = AsmrAudioEngine.encodeWav(samples, sampleRate);

      // Total size: 44 header bytes + 100 * 2 bytes = 244 bytes
      expect(wav.length, 244);

      // Check RIFF header: "RIFF"
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');

      // Check WAVE header: "WAVE"
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');

      // Check fmt sub-chunk: "fmt "
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');

      // Check data sub-chunk: "data"
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');

      // Check data length at offset 40 (little endian 32-bit: 200)
      final byteData = ByteData.sublistView(wav);
      expect(byteData.getUint32(40, Endian.little), 200);

      // Check sample rate at offset 24
      expect(byteData.getUint32(24, Endian.little), sampleRate);

      // Check 16 bits per sample at offset 34
      expect(byteData.getUint16(34, Endian.little), 16);
    });
  });
}
