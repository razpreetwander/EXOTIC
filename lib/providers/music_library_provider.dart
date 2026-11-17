import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../data/music_data.dart';

class MusicLibraryProvider with ChangeNotifier {
  List<Song> _likedSongs = [];
  List<Song> _recentlyPlayed = [];
  List<Playlist> _userPlaylists = [];
  String _searchQuery = '';
  String _selectedGenre = 'All';

  // Getters
  List<Song> get likedSongs => _likedSongs;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Playlist> get userPlaylists => _userPlaylists;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;

  MusicLibraryProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load liked songs (prefer full JSON, fallback to IDs)
    final likedJson = prefs.getStringList('liked_songs_full_json') ?? [];
    if (likedJson.isNotEmpty) {
      _likedSongs = likedJson.map((str) {
        try {
          final s = Song.fromJson(jsonDecode(str));
          s.isLiked = true;
          return s;
        } catch (_) {
          return null;
        }
      }).whereType<Song>().toList();
    } else {
      final likedIds = prefs.getStringList('liked_song_ids') ?? [];
      _likedSongs = MusicLibraryProvider._getSongsFromIds(likedIds);
    }

    final likedIds = _likedSongs.map((s) => s.id).toSet();
    for (var song in MusicData.allSongs) {
      song.isLiked = likedIds.contains(song.id);
    }

    // 2. Load recently played songs
    final recentJson = prefs.getStringList('recent_songs_full_json') ?? [];
    if (recentJson.isNotEmpty) {
      _recentlyPlayed = recentJson.map((str) {
        try {
          return Song.fromJson(jsonDecode(str));
        } catch (_) {
          return null;
        }
      }).whereType<Song>().toList();
    } else {
      final recentIds = prefs.getStringList('recent_song_ids') ?? [];
      _recentlyPlayed = MusicLibraryProvider._getSongsFromIds(recentIds);
    }

    // 3. Load custom playlists JSON
    final playlistsJson = prefs.getStringList('user_playlists_json') ?? [];
    _userPlaylists = playlistsJson.map((str) {
      final map = jsonDecode(str);
      List<Song> songsList = [];
      if (map['songsFull'] != null && map['songsFull'] is List) {
        songsList = (map['songsFull'] as List).map((item) {
          try {
            return Song.fromJson(item is String ? jsonDecode(item) : Map<String, dynamic>.from(item));
          } catch (_) {
            return null;
          }
        }).whereType<Song>().toList();
      } else {
        final songIds = List<String>.from(map['songIds'] ?? []);
        songsList = MusicLibraryProvider._getSongsFromIds(songIds);
      }

      return Playlist(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        coverUrl: map['coverUrl'] ?? 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800',
        songs: songsList,
      );
    }).toList();

    notifyListeners();
  }

  static List<Song> _getSongsFromIds(List<String> ids) {
    List<Song> result = [];
    for (var id in ids) {
      final song = MusicData.allSongs.firstWhere((s) => s.id == id, orElse: () => MusicData.allSongs.first);
      result.add(song);
    }
    return result;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Save liked songs (both IDs and full JSON for 100% compatibility)
    await prefs.setStringList('liked_song_ids', _likedSongs.map((s) => s.id).toList());
    await prefs.setStringList(
      'liked_songs_full_json',
      _likedSongs.map((s) => jsonEncode(s.toJson())).toList(),
    );

    // Save recent songs
    await prefs.setStringList('recent_song_ids', _recentlyPlayed.map((s) => s.id).toList());
    await prefs.setStringList(
      'recent_songs_full_json',
      _recentlyPlayed.map((s) => jsonEncode(s.toJson())).toList(),
    );

    // Save user playlists
    final playlistsData = _userPlaylists.map((pl) {
      return jsonEncode({
        'id': pl.id,
        'title': pl.title,
        'description': pl.description,
        'coverUrl': pl.coverUrl,
        'songIds': pl.songs.map((s) => s.id).toList(),
        'songsFull': pl.songs.map((s) => s.toJson()).toList(),
      });
    }).toList();
    await prefs.setStringList('user_playlists_json', playlistsData);
  }

  bool isLiked(String songId) {
    return _likedSongs.any((s) => s.id == songId);
  }

  void toggleLike(Song song) {
    toggleLikeSong(song);
  }

  void toggleLikeSong(Song song) {
    song.isLiked = !song.isLiked;
    if (song.isLiked) {
      if (!_likedSongs.any((s) => s.id == song.id)) {
        _likedSongs.insert(0, song);
      }
    } else {
      _likedSongs.removeWhere((s) => s.id == song.id);
    }
    _savePrefs();
    notifyListeners();
  }

  void logRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 20);
    }
    _savePrefs();
    notifyListeners();
  }

  void createPlaylist(String title, String description) {
    final newPlaylist = Playlist(
      id: 'custom_pl_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
      songs: [],
    );
    _userPlaylists.insert(0, newPlaylist);
    _savePrefs();
    notifyListeners();
  }

  void addSongToPlaylist(Playlist playlist, Song song) {
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      _savePrefs();
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(Playlist playlist, Song song) {
    playlist.songs.removeWhere((s) => s.id == song.id);
    _savePrefs();
    notifyListeners();
  }

  void deletePlaylist(Playlist playlist) {
    _userPlaylists.removeWhere((p) => p.id == playlist.id);
    _savePrefs();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  List<Song> get filteredSongs {
    return MusicData.allSongs.where((song) {
      final matchesQuery = _searchQuery.isEmpty ||
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.album.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesGenre = (_selectedGenre == 'All') || (song.genre.toLowerCase() == _selectedGenre.toLowerCase());

      return matchesQuery && matchesGenre;
    }).toList();
  }
}
