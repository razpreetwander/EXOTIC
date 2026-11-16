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

    // Load liked song IDs
    final likedIds = prefs.getStringList('liked_song_ids') ?? [];
    _likedSongs = MusicLibraryProvider._getSongsFromIds(likedIds);
    for (var song in MusicData.allSongs) {
      song.isLiked = likedIds.contains(song.id);
    }

    // Load recently played IDs
    final recentIds = prefs.getStringList('recent_song_ids') ?? [];
    _recentlyPlayed = MusicLibraryProvider._getSongsFromIds(recentIds);

    // Load custom playlists JSON
    final playlistsJson = prefs.getStringList('user_playlists_json') ?? [];
    _userPlaylists = playlistsJson.map((str) {
      final map = jsonDecode(str);
      final songIds = List<String>.from(map['songIds'] ?? []);
      return Playlist(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        coverUrl: map['coverUrl'] ?? 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800',
        songs: MusicLibraryProvider._getSongsFromIds(songIds),
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

    await prefs.setStringList('liked_song_ids', _likedSongs.map((s) => s.id).toList());
    await prefs.setStringList('recent_song_ids', _recentlyPlayed.map((s) => s.id).toList());

    final playlistsData = _userPlaylists.map((pl) {
      return jsonEncode({
        'id': pl.id,
        'title': pl.title,
        'description': pl.description,
        'coverUrl': pl.coverUrl,
        'songIds': pl.songs.map((s) => s.id).toList(),
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
