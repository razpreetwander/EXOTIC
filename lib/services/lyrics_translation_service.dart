import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class LyricsTranslationService {
  static final Map<String, List<LyricLine>> _cache = {};

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'original', 'name': 'Original Track', 'native': 'Original', 'flag': '🎵'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🌐'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
    {'code': 'ru', 'name': 'Russian', 'native': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇮🇳'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو', 'flag': '🇵🇰'},
  ];

  /// Translates lyrics in real time while preserving exact line timestamps
  static Future<List<LyricLine>> translateLyrics({
    required String songId,
    required List<LyricLine> originalLyrics,
    required String targetLangCode,
  }) async {
    if (targetLangCode == 'original' || originalLyrics.isEmpty) {
      return originalLyrics;
    }

    final cacheKey = '${songId}_$targetLangCode';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final List<LyricLine> translatedList = [];
      const int chunkSize = 15;

      for (int i = 0; i < originalLyrics.length; i += chunkSize) {
        final chunk = originalLyrics.sublist(i, (i + chunkSize).clamp(0, originalLyrics.length));
        final joinedText = chunk.map((l) => l.text.replaceAll('\n', ' ')).join('\n');

        String translatedBatch = '';

        // Provider 1: MyMemory API (high accuracy for Indian & International languages)
        try {
          final uri = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(joinedText)}&langpair=auto|$targetLangCode');
          final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final text = data['responseData']?['translatedText']?.toString() ?? '';
            if (text.isNotEmpty && !text.toLowerCase().contains('quota exceeded')) {
              translatedBatch = text;
            }
          }
        } catch (_) {}

        // Provider 2: Google GTX Fallback
        if (translatedBatch.isEmpty) {
          try {
            final uri = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLangCode&dt=t&q=${Uri.encodeComponent(joinedText)}');
            final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 5));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final sb = StringBuffer();
              for (final item in (data[0] as List? ?? [])) {
                if (item is List && item.isNotEmpty && item[0] != null) {
                  sb.write(item[0]);
                }
              }
              translatedBatch = sb.toString();
            }
          } catch (_) {}
        }

        final translatedLines = translatedBatch.split('\n');

        for (int j = 0; j < chunk.length; j++) {
          final text = (j < translatedLines.length && translatedLines[j].trim().isNotEmpty)
              ? translatedLines[j].trim()
              : chunk[j].text;
          translatedList.add(LyricLine(timestamp: chunk[j].timestamp, text: text));
        }
      }

      if (translatedList.isNotEmpty) {
        _cache[cacheKey] = translatedList;
        return translatedList;
      }
    } catch (e) {
      debugPrint('Error translating lyrics for $songId: $e');
    }

    return originalLyrics;
  }
}
