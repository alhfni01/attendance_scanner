import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccessBeep() async {
    try {
      await _player.stop();

      await _player.play(
        AssetSource('sounds/Correct.mp3'),
      );
    } catch (e) {
      debugPrint('Success audio playback error: $e');
    }
  }

  static Future<void> playErrorBeep() async {
    try {
      await _player.stop();

      await _player.play(
        AssetSource('sounds/ERROR.mp3'),
      );
    } catch (e) {
      debugPrint('Error audio playback error: $e');
    }
  }
}