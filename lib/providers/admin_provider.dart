import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';
import '../models/album_model.dart';
import '../models/podcast_model.dart';
import '../data/music_data.dart';
import '../services/drive_engine_service.dart';
import '../services/firebase_sync_service.dart';

class AdminProvider with ChangeNotifier {
  // Official New Firebase Project Credentials
  String _appName = 'EXOTIC MUSIC';
  bool _isMaintenanceMode = false;
  String _announcementMessage = 'Welcome to EXOTIC MUSIC! Stream unlimited high-definition music.';
  bool _isVipRequired = false;

  // New Connected Firebase Configuration (exoticglobalmusic)
  final String _firebaseProjectId = 'exoticglobalmusic';
  final String _firebaseDbUrl = 'https://exoticglobalmusic-default-rtdb.firebaseio.com';
  final String _firebaseApiKey = 'AIzaSyCPu271Nc41d8E04PrgXgTT9ZFvRAhZ4Zw';
  final String _firebaseAppId = '1:850962611354:web:66856825dc38bb7d847323';
  final String _firebaseStorageBucket = 'exoticglobalmusic.firebasestorage.app';
  final bool _isFirebaseConnected = true;

  // Realtime Artists Catalog
  List<Artist> _artistsCatalog = [
    Artist(
      id: 'art_01',
      name: 'The Weeknd',
      imageUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400',
      bannerUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=1200',
      bio: 'Canadian singer, songwriter, and record producer known for his sonic versatility and dark lyricism.',
      language: 'English',
      artistType: 'Playback Singer',
      genre: 'Pop / Synthwave',
      monthlyListeners: 105000000,
    ),
    Artist(
      id: 'art_02',
      name: 'Arijit Singh',
      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
      bannerUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200',
      bio: 'Indian playback singer and music composer. The king of soulful Bollywood romantic anthems.',
      language: 'Hindi',
      artistType: 'Playback Singer',
      genre: 'Bollywood',
      monthlyListeners: 42000000,
    ),
    Artist(
      id: 'art_03',
      name: 'Dua Lipa',
      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
      bannerUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=1200',
      bio: 'English and Albanian singer and songwriter. Known for her disco-pop sound.',
      language: 'English',
      artistType: 'Pop Icon',
      genre: 'Pop / Dance',
      monthlyListeners: 78000000,
    ),
  ];

  List<String> _languagesList = ['Hindi', 'Punjabi', 'English', 'Haryanvi', 'Bhojpuri', 'Rajasthani', 'Spanish', 'Tamil'];
  List<String> _artistTypesList = ['Playback Singer', 'Rapper', 'Indie Artist', 'EDM DJ', 'Music Director', 'Sufi Artist', 'Classical Singer'];
  final List<String> _releaseTypes = ['Single Track', 'Full Album'];

  // Custom Admin Playlists
  List<Playlist> _playlistsCatalog = [];

  // Custom Admin Albums & Collections (e.g., Bipolar)
  List<Album> _albumsCatalog = [];

  // Hero Banners Carousel Configurator
  List<Map<String, String>> _heroBanners = [
    {
      'title': 'STARBOY REMASTERED',
      'subtitle': 'Stream the full album in High-Definition Lossless Audio',
      'imageUrl': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=1200',
    },
    {
      'title': 'BOLLYWOOD ROMANTIC ANTHEMS',
      'subtitle': 'Featuring Arijit Singh & Top Premier Artists',
      'imageUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200',
    },
  ];

  // Genres & Moods Manager
  List<Map<String, String>> _genresList = [
    {'name': 'Pop', 'coverUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400'},
    {'name': 'Bollywood', 'coverUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400'},
    {'name': 'Electronic / Synth', 'coverUrl': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400'},
    {'name': 'Hip-Hop / Rap', 'coverUrl': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400'},
    {'name': 'Punjabi Beats', 'coverUrl': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=400'},
  ];

  // Custom Admin Song List
  List<Song> _customSongs = [];
  int _totalStreamCount = 142850;

  // Home Screen Sections Array Manager
  List<String> _homeSectionsList = [
    'From your favorite artists',
    'Fresh finds',
    'Keep recommendation for later',
    'Albums + Singles for you',
    'Popular Radio',
    'Your top artists',
    'Hit Lists for you',
    'Featured Releases',
    'Best of Punjabi',
    'Fresh Punjabi',
    'Charts & Trends',
    'Top Music',
  ];
  String _connectedDevice = 'Exotic Mobile (This Phone)';


  // Getters
  String get appName => _appName;
  bool get isMaintenanceMode => _isMaintenanceMode;
  String get announcementMessage => _announcementMessage;
  bool get isVipRequired => _isVipRequired;
  String get firebaseProjectId => _firebaseProjectId;
  String get firebaseDbUrl => _firebaseDbUrl;
  String get firebaseApiKey => _firebaseApiKey;
  String get firebaseAppId => _firebaseAppId;
  String get firebaseStorageBucket => _firebaseStorageBucket;
  bool get isFirebaseConnected => _isFirebaseConnected;

  List<Artist> get artistsCatalog => _artistsCatalog;
  List<String> get artistsNamesList => _artistsCatalog.map((a) => a.name).toList();
  List<String> get languagesList => _languagesList;
  List<String> get artistTypesList => _artistTypesList;
  List<String> get releaseTypes => _releaseTypes;
  List<Song> get customSongs => _customSongs;
  List<Playlist> get playlistsCatalog => _playlistsCatalog;
  List<Album> get albumsCatalog => _albumsCatalog;
  // Custom Admin Podcasts & Shows
  List<Podcast> _podcastsCatalog = [];

  List<Podcast> get podcastsCatalog => _podcastsCatalog;
  List<Map<String, String>> get heroBanners => _heroBanners;
  List<Map<String, String>> get genresList => _genresList;
  List<String> get homeSectionsList => _homeSectionsList;
  String get connectedDevice => _connectedDevice;
  int get totalStreamCount => _totalStreamCount;

  // Dynamic App Theme Color Controller
  Color _themeAccentColor = const Color(0xE6FFFFFF); // Default Frosted Silver Glass Accent
  String _themeName = 'Transparent Silver Glass';
  bool _isGlassmorphismEnabled = true;

  Color get themeAccentColor => _themeAccentColor;
  String get themeName => _themeName;
  bool get isGlassmorphismEnabled => _isGlassmorphismEnabled;

  List<Song> get allAppSongs => _customSongs.isNotEmpty || _hasLoadedSongsPrefs ? _customSongs : MusicData.allSongs;
  bool _hasLoadedSongsPrefs = false;

  AdminProvider() {
    _loadAdminSettings();
  }

  Future<void> _loadAdminSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appName = prefs.getString('admin_app_name') ?? 'EXOTIC MUSIC';
    _isMaintenanceMode = prefs.getBool('admin_maintenance') ?? false;
    _announcementMessage = prefs.getString('admin_announcement') ?? 'Welcome to EXOTIC MUSIC!';
    _isVipRequired = prefs.getBool('admin_vip_required') ?? false;

    // Load Theme Color & Glassmorphism config
    final savedColor = prefs.getInt('admin_theme_accent_color');
    if (savedColor != null) {
      _themeAccentColor = Color(savedColor);
    }
    _themeName = prefs.getString('admin_theme_name') ?? 'Transparent Silver Glass';
    _isGlassmorphismEnabled = prefs.getBool('admin_glassmorphism') ?? true;

    // Load Languages
    final savedLangs = prefs.getStringList('admin_languages_list');
    if (savedLangs != null && savedLangs.isNotEmpty) {
      _languagesList = savedLangs;
    }

    // Load Artist Types
    final savedTypes = prefs.getStringList('admin_artist_types_list');
    if (savedTypes != null && savedTypes.isNotEmpty) {
      _artistTypesList = savedTypes;
    }

    // Load Saved Artists
    final artistsJson = prefs.getString('admin_artists_catalog');
    if (artistsJson != null) {
      try {
        final List<dynamic> list = jsonDecode(artistsJson);
        _artistsCatalog = list.map((item) => Artist.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error loading saved artists catalog: $e');
      }
    }

    // Load Saved Custom Songs from local prefs
    final songsJson = prefs.getString('admin_custom_songs');
    if (songsJson != null) {
      _hasLoadedSongsPrefs = true;
      try {
        final List<dynamic> list = jsonDecode(songsJson);
        _customSongs = list.map((item) {
          return Song(
            id: item['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
            title: item['title'] ?? 'Untitled Track',
            artist: item['artist'] ?? 'Unknown Artist',
            album: item['album'] ?? 'Exotic Release',
            duration: Duration(seconds: item['durationSeconds'] ?? 210),
            audioUrl: item['audioUrl'] ?? '',
            coverUrl: item['coverUrl'] ?? '',
            genre: item['genre'] ?? 'Pop',
          );
        }).toList();
      } catch (e) {
        debugPrint('Error loading custom admin songs: $e');
      }
    } else {
      // First run: seed from MusicData and save
      _customSongs = List.from(MusicData.allSongs);
      _hasLoadedSongsPrefs = true;
      _saveCustomSongs();
    }

    // Fetch live data from New Firebase Realtime Database (exoticglobalmusic) asynchronously!
    _syncFromFirebase();

    // Initialize Default Playlists if empty
    if (_playlistsCatalog.isEmpty) {
      _playlistsCatalog = [
        Playlist(
          id: 'pl_01',
          title: 'Cyberpunk Synth Beats',
          description: 'High energy futuristic synthwave & electronic dance tracks.',
          coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=800',
          genreTag: 'Electronic',
          songs: allAppSongs.take(3).toList(),
        ),
        Playlist(
          id: 'pl_02',
          title: 'Bollywood Hits 2026',
          description: 'Top trending soulful Bollywood romantic anthems.',
          coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800',
          genreTag: 'Bollywood',
          songs: allAppSongs.where((s) => s.genre.contains('Bollywood')).toList(),
        ),
      ];
    }

    // Initialize Default Albums if empty
    if (_albumsCatalog.isEmpty) {
      _albumsCatalog = [
        Album(
          id: 'alb_01',
          title: 'Starboy Remastered',
          artist: 'The Weeknd',
          coverUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=800',
          releaseYear: '2026',
          songs: allAppSongs.where((s) => s.artist.contains('The Weeknd')).toList(),
        ),
      ];
    }

    // Initialize Default Podcasts if empty
    if (_podcastsCatalog.isEmpty) {
      _podcastsCatalog = [
        Podcast(
          id: 'pod_01',
          title: 'The Joe Rogan Experience',
          publisher: 'Joe Rogan',
          description: 'Long form conversations with comedians, scientists, and experts.',
          coverUrl: 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?q=80&w=400',
          category: 'Podcasts & Talk',
          episodes: allAppSongs.take(2).toList(),
        ),
        Podcast(
          id: 'pod_02',
          title: 'The Ranveer Show (TRS)',
          publisher: 'Ranveer Allahbadia',
          description: 'India\'s smartest podcast exploring life, business, and music.',
          coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
          category: 'Motivation & Music',
          episodes: allAppSongs.skip(1).take(2).toList(),
        ),
      ];
    }

    notifyListeners();
  }

  Future<void> addPodcast(Podcast podcast) async {
    _podcastsCatalog.add(podcast);
    await _savePodcastsCatalog();
    notifyListeners();
  }

  Future<void> updatePodcast(String id, Podcast updated) async {
    final idx = _podcastsCatalog.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _podcastsCatalog[idx] = updated;
      await _savePodcastsCatalog();
      notifyListeners();
    }
  }

  Future<void> deletePodcast(String id) async {
    _podcastsCatalog.removeWhere((p) => p.id == id);
    await _savePodcastsCatalog();
    notifyListeners();
  }

  Future<void> _savePodcastsCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _podcastsCatalog.map((p) => p.toJson()).toList();
      await prefs.setString('admin_podcasts_catalog', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving podcasts catalog: $e');
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      final fbSongs = await FirebaseSyncService.fetchSongsFromFirebase();
      if (fbSongs.isNotEmpty) {
        _customSongs = fbSongs;
        notifyListeners();
      }

      final fbArtists = await FirebaseSyncService.fetchArtistsFromFirebase();
      if (fbArtists.isNotEmpty) {
        _artistsCatalog = fbArtists;
        notifyListeners();
      }

      final fbAnnouncement = await FirebaseSyncService.fetchAnnouncementFromFirebase();
      if (fbAnnouncement != null && fbAnnouncement.isNotEmpty) {
        _announcementMessage = fbAnnouncement;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firebase Auto Sync Error: $e');
    }
  }

  Artist getArtistByName(String name) {
    return _artistsCatalog.firstWhere(
      (a) => a.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Artist(
        id: 'art_default',
        name: name,
        imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
        bio: 'Exotic Premier Artist.',
        language: 'Hindi',
        genre: 'Pop',
      ),
    );
  }

  Future<void> addCustomLanguage(String lang) async {
    final clean = lang.trim();
    if (clean.isNotEmpty && !_languagesList.contains(clean)) {
      _languagesList.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('admin_languages_list', _languagesList);
      notifyListeners();
    }
  }

  Future<void> addCustomArtistType(String type) async {
    final clean = type.trim();
    if (clean.isNotEmpty && !_artistTypesList.contains(clean)) {
      _artistTypesList.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('admin_artist_types_list', _artistTypesList);
      notifyListeners();
    }
  }

  Future<void> addArtistFull(Artist artist) async {
    _artistsCatalog.removeWhere((a) => a.name.toLowerCase() == artist.name.toLowerCase());
    _artistsCatalog.add(artist);
    await _saveArtistsCatalog();
    notifyListeners();
  }

  Future<void> editArtist(Artist updatedArtist) async {
    final idx = _artistsCatalog.indexWhere((a) => a.id == updatedArtist.id || a.name.toLowerCase() == updatedArtist.name.toLowerCase());
    if (idx != -1) {
      _artistsCatalog[idx] = updatedArtist;
    } else {
      _artistsCatalog.add(updatedArtist);
    }
    await _saveArtistsCatalog();
    notifyListeners();
  }

  Future<void> addAlbum(Album album) async {
    _albumsCatalog.removeWhere((a) => a.title.toLowerCase() == album.title.toLowerCase());
    _albumsCatalog.add(album);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_albums_catalog', jsonEncode(_albumsCatalog.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteAlbum(String albumId) async {
    _albumsCatalog.removeWhere((a) => a.id == albumId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_albums_catalog', jsonEncode(_albumsCatalog.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  Future<void> addHeroBanner(String title, String subtitle, String imageUrl) async {
    _heroBanners.add({'title': title, 'subtitle': subtitle, 'imageUrl': imageUrl});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_hero_banners', jsonEncode(_heroBanners));
    FirebaseSyncService.saveHeroBannersToFirebase(_heroBanners);
    notifyListeners();
  }

  Future<void> deleteHeroBanner(int index) async {
    if (index >= 0 && index < _heroBanners.length) {
      _heroBanners.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_hero_banners', jsonEncode(_heroBanners));
      FirebaseSyncService.saveHeroBannersToFirebase(_heroBanners);
      notifyListeners();
    }
  }

  Future<void> addGenre(String name, String coverUrl) async {
    _genresList.add({'name': name, 'coverUrl': coverUrl});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_genres_list', jsonEncode(_genresList));
    FirebaseSyncService.saveGenresToFirebase(_genresList);
    notifyListeners();
  }

  Future<void> deleteGenre(int index) async {
    if (index >= 0 && index < _genresList.length) {
      _genresList.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_genres_list', jsonEncode(_genresList));
      FirebaseSyncService.saveGenresToFirebase(_genresList);
      notifyListeners();
    }
  }

  Future<void> uploadSingleSong({
    required String title,
    required String artist,
    required String album,
    required String audioUrl,
    required String hostedCoverUrl,
    required String genre,
    required String releaseType,
  }) async {
    final String directAudioUrl = DriveEngineService.convertDriveLinkToDirectStream(audioUrl);
    final String cover = hostedCoverUrl.isEmpty
        ? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400'
        : hostedCoverUrl;

    final song = Song(
      id: 'song_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artist,
      album: album.isEmpty ? (releaseType == 'Single Track' ? '$title - Single' : '$title Album') : album,
      duration: const Duration(minutes: 3, seconds: 30),
      audioUrl: directAudioUrl,
      coverUrl: cover,
      genre: genre,
    );

    _customSongs.add(song);

    // Auto route song into Album if title specified
    if (album.isNotEmpty) {
      final existingAlbumIdx = _albumsCatalog.indexWhere((a) => a.title.toLowerCase() == album.toLowerCase());
      if (existingAlbumIdx != -1) {
        _albumsCatalog[existingAlbumIdx].songs.add(song);
      } else {
        _albumsCatalog.add(Album(
          id: 'alb_${DateTime.now().millisecondsSinceEpoch}',
          title: album,
          artist: artist,
          coverUrl: cover,
          songs: [song],
        ));
      }
    }

    await _saveCustomSongs();
    notifyListeners();
  }

  Future<int> uploadDriveFolder({
    required String folderUrlOrData,
    required String hostedCoverUrl,
    required String artistName,
    required String albumName,
    required String genre,
    required String releaseType,
  }) async {
    final parsedSongs = await DriveEngineService.fetchFolderSongsFromDriveApi(
      folderUrlOrId: folderUrlOrData,
      hostedCoverUrl: hostedCoverUrl,
      artistName: artistName,
      albumName: albumName,
      genre: genre,
    );

    _customSongs.addAll(parsedSongs);

    // Auto route full folder songs into an Album Collection automatically!
    if (parsedSongs.isNotEmpty) {
      final String albumTitle = albumName.isEmpty ? 'Exotic Collection' : albumName;
      _albumsCatalog.add(Album(
        id: 'alb_folder_${DateTime.now().millisecondsSinceEpoch}',
        title: albumTitle,
        artist: artistName,
        coverUrl: hostedCoverUrl.isEmpty ? parsedSongs.first.coverUrl : hostedCoverUrl,
        songs: parsedSongs,
      ));
    }

    await _saveCustomSongs();
    notifyListeners();
    return parsedSongs.length;
  }

  Future<void> updateSongDetails(String songId, Song updatedSong) async {
    final customIdx = _customSongs.indexWhere((s) => s.id == songId);
    if (customIdx != -1) {
      _customSongs[customIdx] = updatedSong;
    }

    final musicIdx = MusicData.allSongs.indexWhere((s) => s.id == songId);
    if (musicIdx != -1) {
      MusicData.allSongs[musicIdx] = updatedSong;
    }

    await _saveCustomSongs();
    notifyListeners();
  }

  Future<void> setAppName(String name) async {
    _appName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_app_name', name);
    notifyListeners();
  }

  Future<void> setConnectedDevice(String deviceName) async {
    _connectedDevice = deviceName;
    notifyListeners();
  }

  Future<void> setThemeAccent(Color color, String name) async {
    _themeAccentColor = color;
    _themeName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('admin_theme_accent_color', color.toARGB32());
    await prefs.setString('admin_theme_name', name);
  }

  Future<void> toggleGlassmorphism(bool value) async {
    _isGlassmorphismEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_glassmorphism', value);
  }

  Future<void> addHomeSection(String sectionTitle) async {
    final clean = sectionTitle.trim();
    if (clean.isNotEmpty && !_homeSectionsList.contains(clean)) {
      _homeSectionsList.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('admin_home_sections', _homeSectionsList);
      notifyListeners();
    }
  }

  Future<void> deleteHomeSection(int index) async {
    if (index >= 0 && index < _homeSectionsList.length) {
      _homeSectionsList.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('admin_home_sections', _homeSectionsList);
      notifyListeners();
    }
  }

  Future<void> addPlaylist(Playlist playlist) async {
    _playlistsCatalog.add(playlist);
    FirebaseSyncService.savePlaylistsToFirebase(_playlistsCatalog);
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlistsCatalog.removeWhere((p) => p.id == playlistId);
    FirebaseSyncService.savePlaylistsToFirebase(_playlistsCatalog);
    notifyListeners();
  }

  Future<void> setMaintenanceMode(bool value) async {
    _isMaintenanceMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_maintenance', value);
    notifyListeners();
  }

  Future<void> setAnnouncementMessage(String msg) async {
    _announcementMessage = msg;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_announcement', msg);
    FirebaseSyncService.saveAnnouncementToFirebase(msg);
    notifyListeners();
  }

  Future<void> setVipRequired(bool value) async {
    _isVipRequired = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_vip_required', value);
    notifyListeners();
  }

  Future<void> deleteSong(String songId) async {
    _customSongs.removeWhere((s) => s.id == songId);
    MusicData.allSongs.removeWhere((s) => s.id == songId);
    await _saveCustomSongs();
    notifyListeners();
  }

  Future<void> deleteArtist(String artistId) async {
    _artistsCatalog.removeWhere((a) => a.id == artistId);
    await _saveArtistsCatalog();
    notifyListeners();
  }

  Future<void> _saveArtistsCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _artistsCatalog.map((a) => a.toJson()).toList();
    await prefs.setString('admin_artists_catalog', jsonEncode(data));

    // Live push to Firebase Realtime Database exoticglobalmusic
    FirebaseSyncService.saveArtistsToFirebase(_artistsCatalog);
  }

  Future<void> _saveCustomSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _customSongs.map((s) => {
      'id': s.id,
      'title': s.title,
      'artist': s.artist,
      'album': s.album,
      'durationSeconds': s.duration.inSeconds,
      'audioUrl': s.audioUrl,
      'coverUrl': s.coverUrl,
      'genre': s.genre,
    }).toList();
    await prefs.setString('admin_custom_songs', jsonEncode(data));

    // Live push to Firebase Realtime Database exoticglobalmusic
    FirebaseSyncService.saveSongsToFirebase(_customSongs);
  }

  void incrementStreamCount() {
    _totalStreamCount++;
    notifyListeners();
  }
}
