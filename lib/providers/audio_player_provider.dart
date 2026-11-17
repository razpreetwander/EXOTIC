import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';
import '../data/music_data.dart';
import '../services/drive_engine_service.dart';
import '../services/saavn_api_service.dart';
import '../services/yt_music_service.dart';

enum LoopState { off, loopAll, loopOne }

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isShuffle = false;
  LoopState _loopState = LoopState.loopAll;

  // Equalizer settings
  String _currentEqPreset = 'Exotic Bass';
  final List<double> _eqBands = [4.0, 6.0, 2.0, -1.0, 3.0]; // 5-band gain in dB (-12 to +12)

  // Animated visualizer spectrum values (for UI visualizers)
  List<double> _spectrumBars = [0.2, 0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.8, 0.4];
  Timer? _spectrumTimer;

  // Real-Time Synced Lyrics
  List<LyricLine> _currentLyrics = [];
  bool _isLoadingLyrics = false;
  final Set<String> _playedSongIds = {};

  // Getters
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _playlist.length) ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  LoopState get loopState => _loopState;
  String get currentEqPreset => _currentEqPreset;
  List<double> get eqBands => _eqBands;
  List<double> get spectrumBars => _spectrumBars;
  List<LyricLine> get currentLyrics => _currentLyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;

  AudioPlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      if (_isPlaying) {
        _startSpectrumAnimation();
      } else {
        _stopSpectrumAnimation();
      }
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _handleTrackCompletion();
    });
  }

  void _startSpectrumAnimation() {
    _spectrumTimer?.cancel();
    _spectrumTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!_isPlaying) return;
      final random = Random();
      _spectrumBars = List.generate(9, (index) => 0.15 + random.nextDouble() * 0.85);
      notifyListeners();
    });
  }

  void _stopSpectrumAnimation() {
    _spectrumTimer?.cancel();
    _spectrumBars = List.filled(9, 0.1);
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? contextPlaylist}) async {
    if (contextPlaylist != null && contextPlaylist.isNotEmpty) {
      _playlist = List.from(contextPlaylist);
    }

    Song playableSong = song;

    // 1. YouTube Direct Audio Resolution
    if (playableSong.id.startsWith('yt_')) {
      _isLoading = true;
      notifyListeners();
      try {
        final ytStream = await YtMusicService.getDirectAudioStreamUrl(playableSong.id);
        if (ytStream.isNotEmpty) {
          playableSong = playableSong.copyWith(audioUrl: ytStream);
        }
      } catch (e) {
        debugPrint('Error resolving YouTube direct stream: $e');
      }
    }
    // 2. JioSaavn Stream Resolution
    else if (playableSong.isIncomplete || playableSong.audioUrl.isEmpty) {
      _isLoading = true;
      notifyListeners();
      try {
        final full = await SaavnApiService.getSongById(playableSong.id);
        if (full != null && full.audioUrl.isNotEmpty) {
          playableSong = full;
        }
      } catch (e) {
        debugPrint('Error resolving JioSaavn song stream: $e');
      }
    }

    // 3. Fallback: If song is missing audio URL and not local, resolve via YouTube Engine
    if (playableSong.audioUrl.isEmpty && !playableSong.audioUrl.startsWith('/')) {
      try {
        final fallbackStream = await YtMusicService.resolveFallbackAudio(playableSong.title, playableSong.artist);
        if (fallbackStream.isNotEmpty) {
          playableSong = playableSong.copyWith(audioUrl: fallbackStream);
        }
      } catch (e) {
        debugPrint('Fallback YouTube resolution error: $e');
      }
    }

    int index = _playlist.indexWhere((s) => s.id == playableSong.id);
    if (index == -1) {
      _playlist.insert(0, playableSong);
      index = 0;
    } else {
      _playlist[index] = playableSong;
    }
    _currentIndex = index;
    _playedSongIds.add(playableSong.id);

    _fetchLyricsForSong(playableSong);
    _prefetchSuggestionsIfNeeded(playableSong);
    await _startAudio(playableSong.audioUrl);
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    _playlist = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _playlist.length - 1);
    final song = _playlist[_currentIndex];
    _playedSongIds.add(song.id);
    _fetchLyricsForSong(song);
    _prefetchSuggestionsIfNeeded(song);
    await _startAudio(song.audioUrl);
  }

  void _fetchLyricsForSong(Song song) async {
    _currentLyrics = [];
    _isLoadingLyrics = true;
    notifyListeners();

    try {
      final lyrics = await SaavnApiService.fetchRealtimeLyrics(
        song.title,
        song.artist,
        durationSeconds: song.duration.inSeconds,
        songId: song.id,
      );
      if (currentSong?.id == song.id) {
        _currentLyrics = lyrics;
        _isLoadingLyrics = false;
        notifyListeners();
      }
    } catch (e) {
      if (currentSong?.id == song.id) {
        _isLoadingLyrics = false;
        notifyListeners();
      }
    }
  }

  Future<void> _prefetchSuggestionsIfNeeded(Song song) async {
    final remaining = _playlist.length - 1 - _currentIndex;
    if (remaining <= 3) {
      try {
        final suggestions = await SaavnApiService.getSuggestions(song.id, limit: 12);
        final fresh = suggestions.where((s) => !_playedSongIds.contains(s.id) && !_playlist.any((p) => p.id == s.id)).toList();
        if (fresh.isNotEmpty) {
          _playlist.addAll(fresh);
          notifyListeners();
        } else {
          final artistSongs = await SaavnApiService.searchSongs(song.artist, limit: 10);
          final freshArtist = artistSongs.where((s) => !_playedSongIds.contains(s.id) && !_playlist.any((p) => p.id == s.id)).toList();
          if (freshArtist.isNotEmpty) {
            _playlist.addAll(freshArtist);
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Prefetch suggestions error: $e');
      }
    }
  }

  Future<void> _startAudio(String url) async {
    _isLoading = true;
    _position = Duration.zero;
    _duration = currentSong?.duration ?? const Duration(minutes: 3, seconds: 30);
    _isPlaying = true;
    notifyListeners();

    String playUrl = url.trim();

    // 1. Local Device File Playback
    if (playUrl.startsWith('/') || playUrl.startsWith('file://')) {
      final cleanPath = playUrl.replaceFirst('file://', '');
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(cleanPath));
        _isLoading = false;
        _isPlaying = true;
        _startSpectrumAnimation();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('DeviceFileSource error ($cleanPath): $e');
      }
    }

    // 2. Network Playback via Candidate URLs
    bool success = false;
    final candidates = DriveEngineService.getStreamUrlCandidates(playUrl);

    for (final candidateUrl in candidates) {
      if (candidateUrl.trim().isEmpty) continue;
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(candidateUrl));
        success = true;
        debugPrint("Successfully started playing audio stream: $candidateUrl");
        break;
      } catch (e) {
        debugPrint("Candidate playback error ($candidateUrl): $e");
      }
    }

    // 3. YouTube Fallback Resolution if candidates failed
    if (!success && currentSong != null) {
      try {
        final ytStream = await YtMusicService.resolveFallbackAudio(currentSong!.title, currentSong!.artist);
        if (ytStream.isNotEmpty) {
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(ytStream));
          success = true;
          debugPrint("Successfully recovered with YouTube audio fallback: ${currentSong!.title}");
        }
      } catch (err) {
        debugPrint("YouTube fallback error: $err");
      }
    }

    // 4. Final safety fallback
    if (!success) {
      try {
        await _audioPlayer.play(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
        success = true;
      } catch (err) {
        debugPrint("Fallback audio error: $err");
      }
    }

    _isLoading = false;
    _isPlaying = true;
    _startSpectrumAnimation();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (currentSong == null && _playlist.isNotEmpty) {
      await playSong(_playlist.first);
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> seek(Duration newPosition) async {
    _position = newPosition;
    notifyListeners();
    await _audioPlayer.seek(newPosition);
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      final random = Random();
      _currentIndex = random.nextInt(_playlist.length);
    } else {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else if (_loopState == LoopState.loopAll) {
        _currentIndex = 0;
      } else {
        await _audioPlayer.stop();
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    final song = _playlist[_currentIndex];
    _playedSongIds.add(song.id);
    _fetchLyricsForSong(song);
    _prefetchSuggestionsIfNeeded(song);
    await _startAudio(song.audioUrl);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    if (_position.inSeconds > 4) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      _currentIndex = _playlist.length - 1;
    }

    final song = _playlist[_currentIndex];
    _playedSongIds.add(song.id);
    _fetchLyricsForSong(song);
    _prefetchSuggestionsIfNeeded(song);
    await _startAudio(song.audioUrl);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleLoop() {
    if (_loopState == LoopState.off) {
      _loopState = LoopState.loopAll;
    } else if (_loopState == LoopState.loopAll) {
      _loopState = LoopState.loopOne;
    } else {
      _loopState = LoopState.off;
    }
    notifyListeners();
  }

  void _handleTrackCompletion() async {
    if (_loopState == LoopState.loopOne && currentSong != null) {
      seek(Duration.zero);
      _audioPlayer.resume();
    } else {
      if (currentSong != null) {
        await _prefetchSuggestionsIfNeeded(currentSong!);
      }
      playNext();
    }
  }

  void setEqPreset(String presetName) {
    _currentEqPreset = presetName;
    switch (presetName) {
      case 'Exotic Bass':
        _eqBands[0] = 8.0;
        _eqBands[1] = 5.0;
        _eqBands[2] = 1.0;
        _eqBands[3] = 0.0;
        _eqBands[4] = 3.0;
        break;
      case 'Pop Energy':
        _eqBands[0] = 3.0;
        _eqBands[1] = 4.0;
        _eqBands[2] = 6.0;
        _eqBands[3] = 2.0;
        _eqBands[4] = 4.0;
        break;
      case 'Rock Synth':
        _eqBands[0] = 6.0;
        _eqBands[1] = 2.0;
        _eqBands[2] = -1.0;
        _eqBands[3] = 4.0;
        _eqBands[4] = 7.0;
        break;
      case 'Vocal Warmth':
        _eqBands[0] = 1.0;
        _eqBands[1] = 3.0;
        _eqBands[2] = 6.0;
        _eqBands[3] = 4.0;
        _eqBands[4] = 1.0;
        break;
      case 'Flat':
      default:
        for (int i = 0; i < 5; i++) {
          _eqBands[i] = 0.0;
        }
    }
    notifyListeners();
  }

  void updateEqBand(int index, double gainDb) {
    if (index >= 0 && index < _eqBands.length) {
      _eqBands[index] = gainDb;
      _currentEqPreset = 'Custom';
      notifyListeners();
    }
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        if (_playlist.isNotEmpty) {
          _currentIndex = _currentIndex % _playlist.length;
          _startAudio(_playlist[_currentIndex].audioUrl);
        } else {
          _currentIndex = -1;
          _audioPlayer.stop();
          _isPlaying = false;
        }
      }
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _spectrumTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
