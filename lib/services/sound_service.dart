import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool isSoundEnabled = true;

  // Cache generated WAV bytes for instant replay
  Uint8List? _cardDealWav;
  Uint8List? _cardPlayWav;
  Uint8List? _trumpRevealWav;
  Uint8List? _trickWinWav;
  Uint8List? _bidWav;
  Uint8List? _passWav;
  Uint8List? _winWav;
  Uint8List? _loseWav;

  Future<void> init() async {
    _cardDealWav = _generateSweepWav(startFreq: 300, endFreq: 800, durationMs: 70);
    _cardPlayWav = _generateSnapWav();
    _trumpRevealWav = _generateFanfareWav([523.25, 659.25, 783.99, 1046.50]); // C, E, G, High C
    _trickWinWav = _generateChimeWav([587.33, 880.00]); // D5, A5
    _bidWav = _generateToneWav(frequency: 660, durationMs: 60);
    _passWav = _generateToneWav(frequency: 240, durationMs: 90);
    _winWav = _generateFanfareWav([523.25, 659.25, 783.99, 1046.50, 1318.51]);
    _loseWav = _generateFanfareWav([400.0, 350.0, 300.0, 220.0]);
  }

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
  }

  Future<void> playCardDeal() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      if (_cardDealWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_cardDealWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playCardPlay() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.lightImpact();
      if (_cardPlayWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_cardPlayWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playTrumpReveal() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      if (_trumpRevealWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_trumpRevealWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> playTrickWin() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      if (_trickWinWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_trickWinWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playBid() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      if (_bidWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_bidWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playPass() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      if (_passWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_passWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playRoundWin() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      if (_winWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_winWav!));
      }
    } catch (_) {}
  }

  Future<void> playRoundLose() async {
    if (!isSoundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      if (_loseWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_loseWav!));
      }
    } catch (_) {}
  }

  Future<void> playButtonClick() async {
    if (!isSoundEnabled) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  // --- In-Memory WAV Byte Generators ---

  Uint8List _generateToneWav({required double frequency, required int durationMs}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = 1.0 - (i / numSamples); // Linear decay
      final double sample = sin(2 * pi * frequency * t) * envelope * 0.7;
      final int sampleInt16 = (sample * 32767).toInt().clamp(-32768, 32767);
      pcmData.setInt16(i * 2, sampleInt16, Endian.little);
    }

    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
  }

  Uint8List _generateSweepWav({
    required double startFreq,
    required double endFreq,
    required int durationMs,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double progress = i / numSamples;
      final double freq = startFreq + (endFreq - startFreq) * progress;
      final double t = i / sampleRate;
      final double envelope = sin(pi * progress); // Bell envelope
      final double sample = sin(2 * pi * freq * t) * envelope * 0.5;
      final int sampleInt16 = (sample * 32767).toInt().clamp(-32768, 32767);
      pcmData.setInt16(i * 2, sampleInt16, Endian.little);
    }

    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
  }

  Uint8List _generateSnapWav() {
    const int sampleRate = 22050;
    const int durationMs = 45;
    final int numSamples = (sampleRate * (durationMs / 1000)).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);
    final Random rand = Random();

    for (int i = 0; i < numSamples; i++) {
      final double envelope = exp(-i / (sampleRate * 0.008)); // Sharp exponential decay
      final double tone = sin(2 * pi * 880 * (i / sampleRate));
      final double noise = (rand.nextDouble() * 2 - 1) * 0.3;
      final double sample = (tone * 0.7 + noise) * envelope * 0.8;
      final int sampleInt16 = (sample * 32767).toInt().clamp(-32768, 32767);
      pcmData.setInt16(i * 2, sampleInt16, Endian.little);
    }

    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
  }

  Uint8List _generateChimeWav(List<double> freqs) {
    const int sampleRate = 22050;
    const int noteDurationMs = 120;
    final int totalSamples = (sampleRate * (noteDurationMs * freqs.length / 1000)).toInt();
    final ByteData pcmData = ByteData(totalSamples * 2);

    int sampleOffset = 0;
    final int noteSamples = (sampleRate * (noteDurationMs / 1000)).toInt();

    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final double t = i / sampleRate;
        final double envelope = exp(-i / (sampleRate * 0.08));
        final double sample = sin(2 * pi * freq * t) * envelope * 0.6;
        final int sampleInt16 = (sample * 32767).toInt().clamp(-32768, 32767);
        pcmData.setInt16((sampleOffset + i) * 2, sampleInt16, Endian.little);
      }
      sampleOffset += noteSamples;
    }

    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
  }

  Uint8List _generateFanfareWav(List<double> freqs) {
    const int sampleRate = 22050;
    const int noteDurationMs = 110;
    final int totalSamples = (sampleRate * (noteDurationMs * freqs.length / 1000)).toInt();
    final ByteData pcmData = ByteData(totalSamples * 2);

    int sampleOffset = 0;
    final int noteSamples = (sampleRate * (noteDurationMs / 1000)).toInt();

    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final double t = i / sampleRate;
        final double envelope = (1.0 - (i / noteSamples) * 0.5);
        final double sample = (sin(2 * pi * freq * t) + 0.3 * sin(4 * pi * freq * t)) * envelope * 0.5;
        final int sampleInt16 = (sample * 32767).toInt().clamp(-32768, 32767);
        pcmData.setInt16((sampleOffset + i) * 2, sampleInt16, Endian.little);
      }
      sampleOffset += noteSamples;
    }

    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
  }

  Uint8List _buildWavHeader(Uint8List pcmBytes, int sampleRate) {
    final int totalDataLen = pcmBytes.length;
    final int totalChunkLen = totalDataLen + 36;
    const int channels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);

    final ByteData header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, totalChunkLen, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    // fmt subchunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, channels * (bitsPerSample ~/ 8), Endian.little); // BlockAlign
    header.setUint16(34, bitsPerSample, Endian.little);
    // data subchunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, totalDataLen, Endian.little);

    final Uint8List wavBytes = Uint8List(44 + totalDataLen);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());
    wavBytes.setRange(44, 44 + totalDataLen, pcmBytes);
    return wavBytes;
  }
}
