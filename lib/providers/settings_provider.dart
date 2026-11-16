import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isVipActive = true;
  bool _gaplessPlayback = true;
  bool _autoplay = true;
  bool _dataSaver = false;
  bool _privateSession = false;
  bool _canvasVisualizer = true;
  bool _pushNotifications = true;
  String _audioQuality = 'Ultra HD (FLAC 24-bit/96kHz)';
  String _appLanguage = 'English';

  bool get isVipActive => _isVipActive;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get autoplay => _autoplay;
  bool get dataSaver => _dataSaver;
  bool get privateSession => _privateSession;
  bool get canvasVisualizer => _canvasVisualizer;
  bool get pushNotifications => _pushNotifications;
  String get audioQuality => _audioQuality;
  String get appLanguage => _appLanguage;

  SettingsProvider() {
    _loadSettingsFromStorage();
  }

  Future<void> _loadSettingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVipActive = prefs.getBool('setting_vip') ?? true;
      _gaplessPlayback = prefs.getBool('setting_gapless') ?? true;
      _autoplay = prefs.getBool('setting_autoplay') ?? true;
      _dataSaver = prefs.getBool('setting_datasaver') ?? false;
      _privateSession = prefs.getBool('setting_private_session') ?? false;
      _canvasVisualizer = prefs.getBool('setting_canvas') ?? true;
      _pushNotifications = prefs.getBool('setting_notifications') ?? true;
      _audioQuality = prefs.getString('setting_quality') ?? 'Ultra HD (FLAC 24-bit/96kHz)';
      _appLanguage = prefs.getString('setting_language') ?? 'English';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> toggleVip(bool value) async {
    _isVipActive = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_vip', value);
  }

  Future<void> toggleGapless(bool value) async {
    _gaplessPlayback = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_gapless', value);
  }

  Future<void> toggleAutoplay(bool value) async {
    _autoplay = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_autoplay', value);
  }

  Future<void> toggleDataSaver(bool value) async {
    _dataSaver = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_datasaver', value);
  }

  Future<void> togglePrivateSession(bool value) async {
    _privateSession = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_private_session', value);
  }

  Future<void> toggleCanvasVisualizer(bool value) async {
    _canvasVisualizer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_canvas', value);
  }

  Future<void> toggleNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_notifications', value);
  }

  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_quality', quality);
  }

  Future<void> setAppLanguage(String lang) async {
    _appLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_language', lang);
  }
}
