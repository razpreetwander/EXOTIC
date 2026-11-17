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
  String _audioQuality = 'High Fidelity Streaming';
  String _downloadQuality = 'High Quality';
  String _appLanguage = 'English';
  String _username = 'Exotic User';
  String _email = 'user@exoticglobal.com';
  double _crossfadeDuration = 4.0;
  bool _audioNormalization = true;
  bool _downloadWifiOnly = true;
  bool _showExplicitContent = true;
  bool _listeningActivity = true;
  double _cacheSizeMb = 142.8;

  bool get isVipActive => _isVipActive;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get autoplay => _autoplay;
  bool get dataSaver => _dataSaver;
  bool get privateSession => _privateSession;
  bool get canvasVisualizer => _canvasVisualizer;
  bool get pushNotifications => _pushNotifications;
  String get audioQuality => _audioQuality;
  String get downloadQuality => _downloadQuality;
  String get appLanguage => _appLanguage;
  String get username => _username;
  String get email => _email;
  double get crossfadeDuration => _crossfadeDuration;
  bool get audioNormalization => _audioNormalization;
  bool get downloadWifiOnly => _downloadWifiOnly;
  bool get showExplicitContent => _showExplicitContent;
  bool get listeningActivity => _listeningActivity;
  double get cacheSizeMb => _cacheSizeMb;

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
      _audioQuality = prefs.getString('setting_quality') ?? 'High Fidelity Streaming';
      _downloadQuality = prefs.getString('setting_dl_quality') ?? 'High Quality';
      _appLanguage = prefs.getString('setting_language') ?? 'English';
      _username = prefs.getString('setting_username') ?? prefs.getString('user_username') ?? 'Exotic User';
      _email = prefs.getString('setting_email') ?? prefs.getString('user_email') ?? 'user@exoticglobal.com';
      _crossfadeDuration = prefs.getDouble('setting_crossfade') ?? 4.0;
      _audioNormalization = prefs.getBool('setting_normalization') ?? true;
      _downloadWifiOnly = prefs.getBool('setting_wifi_only') ?? true;
      _showExplicitContent = prefs.getBool('setting_explicit') ?? true;
      _listeningActivity = prefs.getBool('setting_listening_act') ?? true;
      _cacheSizeMb = prefs.getDouble('setting_cache_size') ?? 142.8;
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

  Future<void> setDownloadQuality(String quality) async {
    _downloadQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_dl_quality', quality);
  }

  Future<void> setAppLanguage(String lang) async {
    _appLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_language', lang);
  }

  Future<void> setUsername(String name) async {
    _username = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_username', name);
  }

  Future<void> setEmail(String mail) async {
    _email = mail;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_email', mail);
  }

  Future<void> updateProfile({required String username, required String email}) async {
    _username = username;
    _email = email;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_username', username);
    await prefs.setString('setting_email', email);
  }

  Future<void> setCrossfade(double seconds) async {
    _crossfadeDuration = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('setting_crossfade', seconds);
  }

  Future<void> toggleAudioNormalization(bool value) async {
    _audioNormalization = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_normalization', value);
  }

  Future<void> toggleDownloadWifiOnly(bool value) async {
    _downloadWifiOnly = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_wifi_only', value);
  }

  Future<void> toggleExplicitContent(bool value) async {
    _showExplicitContent = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_explicit', value);
  }

  Future<void> toggleListeningActivity(bool value) async {
    _listeningActivity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_listening_act', value);
  }

  Future<double> clearCache() async {
    final cleared = _cacheSizeMb;
    _cacheSizeMb = 0.0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('setting_cache_size', 0.0);
    return cleared;
  }
}
