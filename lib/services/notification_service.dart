import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.global.exotic/native_notification');

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static Function()? onPreviousCallback;
  static Function()? onPlayPauseCallback;
  static Function()? onNextCallback;

  static Timer? _inactivityTimer;
  static Timer? _hourlyCronTimer;
  static Song? _lastPlayedSong;
  static bool _isInitialized = false;

  /// Initialize Native Notification Channels, Callbacks & Hourly Schedules
  static void initialize({
    Function()? onPrevious,
    Function()? onPlayPause,
    Function()? onNext,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    onPreviousCallback = onPrevious;
    onPlayPauseCallback = onPlayPause;
    onNextCallback = onNext;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMediaAction':
          final action = call.arguments as String?;
          if (action == 'previous') {
            onPreviousCallback?.call();
          } else if (action == 'play_pause') {
            onPlayPauseCallback?.call();
          } else if (action == 'next') {
            onNextCallback?.call();
          }
          break;
      }
    });

    _startHourlyRecommendationSchedule();
  }

  /// 1. CHECK & REQUEST PERMISSION
  static Future<bool> checkPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('checkNotificationPermission') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestNotificationPermission') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// 2. MEDIA PLAYBACK NOTIFICATION (Lockscreen Player with MediaStyle & Controls)
  static Future<void> showPlaybackNotification({
    required Song song,
    required bool isPlaying,
  }) async {
    _lastPlayedSong = song;
    _cancelInactivityTimer();

    try {
      await _channel.invokeMethod('showMediaNotification', {
        'title': song.title.isNotEmpty ? song.title : 'Now Playing',
        'artist': song.artist.isNotEmpty ? song.artist : 'EXOTIC MUSIC',
        'album': song.album,
        'isPlaying': isPlaying,
        'coverUrl': song.coverUrl,
      });
    } catch (e) {
      debugPrint('Error showing playback notification: $e');
    }
  }

  static Future<void> hidePlaybackNotification() async {
    try {
      await _channel.invokeMethod('hideMediaNotification');
    } catch (_) {}
  }

  /// 3. FIRST TIME WELCOME APPRECIATION NOTIFICATION
  static Future<void> checkAndShowWelcomeNotification(String preferredLanguage, String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool alreadyShown = prefs.getBool('welcome_notification_sent') ?? false;
      if (alreadyShown) return;

      final name = userName.trim().isNotEmpty ? userName.trim() : 'Rockstar';
      final lang = preferredLanguage.trim().toLowerCase();

      String title = '';
      String body = '';

      if (lang == 'punjabi') {
        title = 'Sat Sri Akal $name ji! 🦁💥';
        body = 'EXOTIC MUSIC te swaagat hai! 🎧 Pure studio sound, vakhra swag te bina kisi ad de gano da maza lo! Dil khol ke suno! 🎵🔥';
      } else if (lang == 'hindi') {
        title = 'स्वागत है $name! 💖✨';
        body = 'EXOTIC MUSIC की दुनिया में आपका स्वागत है! 🎧 Dil se suniye apne favorite artists ko pure high-definition sound ke saath! 🎶🔥';
      } else {
        title = 'Welcome to EXOTIC MUSIC, $name! 🚀✨';
        body = 'Your personalized high-fidelity music paradise is unlocked. Enjoy 320kbps lossless streaming with zero interruptions! 🎧💎';
      }

      await _channel.invokeMethod('showCustomNotification', {
        'id': 1000,
        'title': title,
        'body': body,
      });

      await prefs.setBool('welcome_notification_sent', true);
    } catch (e) {
      debugPrint('Error in welcome notification: $e');
    }
  }

  /// 4. 5-MINUTE INACTIVITY NOTIFICATION (User left music paused or closed)
  static void onPlaybackPausedOrStopped(Song? lastSong) {
    if (lastSong != null) {
      _lastPlayedSong = lastSong;
    }
    _cancelInactivityTimer();

    // Trigger after 5 minutes of inactivity
    _inactivityTimer = Timer(const Duration(minutes: 5), () async {
      final songTitle = _lastPlayedSong?.title ?? 'apna favorite gaana';
      final songArtist = _lastPlayedSong?.artist ?? 'EXOTIC';

      final message = _getRandomInactivityMessage(songTitle, songArtist);

      try {
        await _channel.invokeMethod('showCustomNotification', {
          'id': 2005,
          'title': message['title'],
          'body': message['body'],
        });
      } catch (_) {}
    });
  }

  static void onPlaybackResumed() {
    _cancelInactivityTimer();
  }

  static void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// 5. HOURLY TASTE-BASED NOTIFICATION SCHEDULE
  static void _startHourlyRecommendationSchedule() {
    _hourlyCronTimer?.cancel();

    // Check hourly (every 60 minutes)
    _hourlyCronTimer = Timer.periodic(const Duration(minutes: 60), (timer) async {
      final now = DateTime.now();
      final hour = now.hour;

      // Quiet Hours Rule: 12 AM (0) to 5 AM (5) - Send only once around 2 AM
      if (hour >= 0 && hour <= 5) {
        if (hour != 2) return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final preferredArtists = prefs.getStringList('user_preferred_artists') ?? [];
        final preferredLanguages = prefs.getStringList('user_preferred_languages') ?? [];

        final String artist = preferredArtists.isNotEmpty
            ? preferredArtists[Random().nextInt(preferredArtists.length)]
            : 'Arijit Singh';
        final String lang = preferredLanguages.isNotEmpty ? preferredLanguages.first : 'Hindi';

        final message = _getRandomHourlyTasteMessage(artist, lang, hour);

        await _channel.invokeMethod('showCustomNotification', {
          'id': 3000 + hour,
          'title': message['title'],
          'body': message['body'],
        });
      } catch (e) {
        debugPrint('Hourly recommendation error: $e');
      }
    });
  }

  /// =========================================================================
  /// 6. MASSIVE 1000+ COMBINATORIAL NOTIFICATION MESSAGE ENGINE
  /// (Loaded with Flirts, Dialogues, Memes, Bollywood/Punjabi Swag & Custom Emojis)
  /// =========================================================================

  static final List<String> _emojiCombos = [
    '🎵🎧💥💓💗',
    '🎙️🥰🤩😍✨',
    '💀👾✨💯🔥',
    '🫀💪🏻🫶🏻🤌🏻🫰🏻',
    '🥷🏻🧔🏻💃🏻🕺🏻👑',
    '🌷🥀🌹🌈🏖️',
    '🐻❄️🐼🐨🐰',
    '🚀🛸🚁⚡💎',
    '🎩🪄💿📀💽',
    '❤️💜🩵🩷🔥',
    '🎼🎵🎶🏁🔝',
    '🔮🧿💌📣💫',
  ];

  static Map<String, String> _getRandomInactivityMessage(String songTitle, String artist) {
    final random = Random();
    final emojis = _emojiCombos[random.nextInt(_emojiCombos.length)];

    final List<Map<String, String>> templates = [
      {
        'title': 'Arey yaar, adhoora chhod diya? 🥺💔',
        'body': '“$songTitle” ki beat tera intezaar kar rahi hai... Itni berukhi achhi nahi hoti! Wapas aao na $emojis',
      },
      {
        'title': 'Bade bade deshon mein... 🍷✨',
        'body': 'Aisi choti choti baatein hoti rehti hain, par “$songTitle” pause karna mana hai Senorita! Play dabao $emojis',
      },
      {
        'title': 'Dil toota ya network chhoota? 💔🎧',
        'body': '$artist ke gaane pe pause lagana jurm hai janaab! Chalo turant resume karo $emojis',
      },
      {
        'title': '5 minute ho gaye boss! ⏱️🔥',
        'body': 'Silence se dosti mat karo, “$songTitle” ki bass drop hone wali thi! Aaja wapas $emojis',
      },
      {
        'title': 'Ek tarfa pyaar ki taakat... 💘🎙️',
        'body': 'Ye gaana aur tumhare kaan, perfect match hain! “$songTitle” chalao aur vibe continue karo $emojis',
      },
      {
        'title': 'Kehndi hundi si... 🦁💥',
        'body': 'Gaana poora sunna hai! Beech me chhod ke kahan nikal liye? Resume “$songTitle” now $emojis',
      },
      {
        'title': 'Gusse me ho kya? 🥰🌹',
        'body': 'Maan jao na, tumhare favourite $artist ka track bina sune so jaoge kya? Tap karke play karo $emojis',
      },
      {
        'title': 'Mogambo khush nahi hua! 💀⚡',
        'body': 'Kyunki tumne “$songTitle” band kar diya! Sharafat se gaana on karo $emojis',
      },
      {
        'title': 'Coffee thandi ho rahi hai aur gaana bhi! ☕🎶',
        'body': 'Utho muskurao, headphones lagao aur “$songTitle” ko pura suno $emojis',
      },
      {
        'title': 'Missing the vibe already? 🌌💎',
        'body': '$artist ki awaaz sunke din ban jata hai, play dabao aur mood fresh karo $emojis',
      },
      {
        'title': 'Tumhe koi aur sunne laga hai kya? 👁️💔',
        'body': 'Humein toh laga tum sirf EXOTIC ke ho! Wapas aao aur “$songTitle” bajao $emojis',
      },
      {
        'title': 'Don ko pakadna mushkil hai... 🥷🏻🔥',
        'body': 'Par “$songTitle” dubara play karna bilkul aasan! Just 1 tap and vibe is back $emojis',
      },
    ];

    return templates[random.nextInt(templates.length)];
  }

  static Map<String, String> _getRandomHourlyTasteMessage(String artist, String language, int hour) {
    final random = Random();
    final emojis = _emojiCombos[random.nextInt(_emojiCombos.length)];

    // Night Time (12 AM to 5 AM)
    if (hour >= 0 && hour <= 5) {
      final nightTemplates = [
        {
          'title': 'Neend nahi aa rahi na? 🌙💤',
          'body': 'Der raat, slow acoustic music aur $artist ke bol... Chalo ek sukoon bhara gaana sunte hain $emojis',
        },
        {
          'title': 'Late Night Overthinking? 🌌🎧',
          'body': 'Dimag ko rest do aur headphones pe $artist ka chill track on karo. Sweet dreams $emojis',
        },
        {
          'title': 'Raat akeli hai, gaana zaroori hai 🕯️✨',
          'body': 'Sone se pehle $artist ki soft melody suno, subah energy double hogi $emojis',
        },
        {
          'title': 'Midnight VIP Club on EXOTIC 🍸🎙️',
          'body': 'Duniya so rahi hai aur aapki playlist jaag rahi hai. Lo-fi beats ready hain $emojis',
        },
      ];
      return nightTemplates[random.nextInt(nightTemplates.length)];
    }

    // Morning Time (6 AM to 11 AM)
    if (hour >= 6 && hour <= 11) {
      final morningTemplates = [
        {
          'title': 'Subah ki pehli chai aur $artist! ☕🌅',
          'body': 'Din ki shuruaat jabardast energy ke sath karo! New hits aapka wait kar rahe hain $emojis',
        },
        {
          'title': 'Good Morning Rockstar! ⚡🚀',
          'body': 'Aalas chhod, beat pakad! $artist ka pumped-up track ready hai EXOTIC par $emojis',
        },
        {
          'title': 'Utho anari, gaane suno pyari! 🌸🎶',
          'body': 'Aaj ka din bohot khoobsurat hoga agar background me $artist baj raha ho $emojis',
        },
        {
          'title': 'Breakfast with Pure Sound 🥞🍓',
          'body': 'Chai garam hai aur $artist ke superhits usse bhi zyada hot! Tap to listen $emojis',
        },
      ];
      return morningTemplates[random.nextInt(morningTemplates.length)];
    }

    // Afternoon & Evening (12 PM to 11 PM) - Super Flirty, Bollywood Dialogues, Memes & Swagger
    final generalTemplates = [
      {
        'title': 'Karan Aujla ke bol te teri vibe! 🦁💥',
        'body': '“Jihna naalon karde compare goriye...” $artist ke fresh tracks EXOTIC pe full blast chalao $emojis',
      },
      {
        'title': 'Tum itni pyari ho toh playlist kyu boring? 🥰💖',
        'body': '$artist ke romantic numbers suno, dil ko sukoon aur chehre pe smile dono aayenge $emojis',
      },
      {
        'title': 'Parampara, Pratishtha, Anushasan! 🏛️🔥',
        'body': 'Hamara niyam hai: har ghante $artist ka ek gana bajana anivarya hai! Tap to play $emojis',
      },
      {
        'title': 'Weekend wali feeling har ghante! 🏖️🍹',
        'body': 'Work load zyada hai? Headphones lagao aur $artist ke gano me kho jao $emojis',
      },
      {
        'title': 'Picture abhi baaki hai mere dost! 🎬✨',
        'body': 'Top chartbuster tracks sirf aapke taste ke liye arrange kiye hain $artist se $emojis',
      },
      {
        'title': 'Dua Lipa & Weeknd level sound! 🚀💎',
        'body': 'International quality bass aapke device pe. Studio mode enable karo aur suno $emojis',
      },
      {
        'title': 'Apna Time Aayega? Nahi, aa gaya! 🎤💯',
        'body': '$artist ke supercharged tracks ke sath flow me aao. Full volume on! $emojis',
      },
      {
        'title': 'Kya kar rahe ho akele akele? 👁️‍🗨️💓',
        'body': 'EXOTIC MUSIC ko sath rakho, $artist ke latest trending gaane ready hain $emojis',
      },
      {
        'title': 'Diljit Dosanjh di vibe te desi swag! 🪕🔥',
        'body': 'Bhangra beats ya sad acoustic? Jo chahiye sab live hai aapki stream pe $emojis',
      },
      {
        'title': 'Sholay ka Gabbar bhi naachte huye bola... 💥🤠',
        'body': '“Ye gaane kitne mast hain re Samba!” $artist ki playlist tap karke dekho $emojis',
      },
      {
        'title': 'Bas 1 minute nikal lo apne liye 🎧✨',
        'body': 'Duniya ki bheed se alag, $artist ka melodious magic aapko relax kar dega $emojis',
      },
      {
        'title': 'Zindagi na milegi dobara! 🏎️🌴',
        'body': 'Road trip wali vibe le aao apne kamre me! $artist ke popular tracks live hain $emojis',
      },
    ];

    return generalTemplates[random.nextInt(generalTemplates.length)];
  }
}
