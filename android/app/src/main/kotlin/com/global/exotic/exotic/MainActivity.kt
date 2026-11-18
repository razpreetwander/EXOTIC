package com.global.exotic.exotic

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val AUDIO_CHANNEL = "com.global.exotic/device_audio"
    private val NOTIF_CHANNEL = "com.global.exotic/native_notification"

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingNotifPermissionResult: MethodChannel.Result? = null
    private val STORAGE_PERMISSION_CODE = 4040
    private val NOTIFICATION_PERMISSION_CODE = 5050

    private val PLAYBACK_CHANNEL_ID = "exotic_playback_channel"
    private val ALERTS_CHANNEL_ID = "exotic_alerts_channel"
    private val PLAYBACK_NOTIFICATION_ID = 1001

    private var flutterMethodChannel: MethodChannel? = null
    private var mediaReceiver: BroadcastReceiver? = null

    companion object {
        const val ACTION_PREVIOUS = "com.global.exotic.ACTION_PREVIOUS"
        const val ACTION_PLAY_PAUSE = "com.global.exotic.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.global.exotic.ACTION_NEXT"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannels()

        // 1. Device Audio Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(checkStoragePermission())
                }
                "requestPermission" -> {
                    if (checkStoragePermission()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
                        } else {
                            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
                        }
                        ActivityCompat.requestPermissions(this, permissions, STORAGE_PERMISSION_CODE)
                    }
                }
                "getDeviceAudioFiles" -> {
                    try {
                        val songs = fetchMediaStoreAudio()
                        result.success(songs)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Native Notification Channel
        flutterMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL)
        flutterMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    result.success(checkNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    if (checkNotificationPermission()) {
                        result.success(true)
                    } else {
                        pendingNotifPermissionResult = result
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_PERMISSION_CODE
                            )
                        } else {
                            result.success(true)
                        }
                    }
                }
                "showMediaNotification" -> {
                    val title = call.argument<String>("title") ?: "Now Playing"
                    val artist = call.argument<String>("artist") ?: "EXOTIC MUSIC"
                    val album = call.argument<String>("album") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true
                    val coverUrl = call.argument<String>("coverUrl")
                    showMediaNotification(title, artist, album, isPlaying, coverUrl)
                    result.success(true)
                }
                "hideMediaNotification" -> {
                    hideMediaNotification()
                    result.success(true)
                }
                "showCustomNotification" -> {
                    val id = call.argument<Int>("id") ?: 2001
                    val title = call.argument<String>("title") ?: "EXOTIC MUSIC"
                    val body = call.argument<String>("body") ?: ""
                    showCustomNotification(id, title, body)
                    result.success(true)
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id") ?: 2001
                    cancelNotification(id)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Register Media Controls BroadcastReceiver
        registerMediaReceiver()
    }

    private fun registerMediaReceiver() {
        val filter = IntentFilter().apply {
            addAction(ACTION_PREVIOUS)
            addAction(ACTION_PLAY_PAUSE)
            addAction(ACTION_NEXT)
        }
        mediaReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_PREVIOUS -> flutterMethodChannel?.invokeMethod("onMediaAction", "previous")
                    ACTION_PLAY_PAUSE -> flutterMethodChannel?.invokeMethod("onMediaAction", "play_pause")
                    ACTION_NEXT -> flutterMethodChannel?.invokeMethod("onMediaAction", "next")
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(mediaReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            mediaReceiver?.let { unregisterReceiver(it) }
        } catch (_: Exception) {}
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val playbackChannel = NotificationChannel(
                PLAYBACK_CHANNEL_ID,
                "EXOTIC Music Player",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows currently playing song with playback controls on lockscreen"
                setShowBadge(false)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(playbackChannel)

            val alertsChannel = NotificationChannel(
                ALERTS_CHANNEL_ID,
                "EXOTIC Music Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Music recommendations, welcome messages, and activity reminders"
                enableLights(true)
                lightColor = Color.parseColor("#FF7A00")
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(alertsChannel)
        }
    }

    private fun showMediaNotification(
        title: String,
        artist: String,
        album: String,
        isPlaying: Boolean,
        coverUrl: String?
    ) {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = Intent(ACTION_PREVIOUS)
        val prevPendingIntent = PendingIntent.getBroadcast(
            this, 1, prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIntent = Intent(ACTION_PLAY_PAUSE)
        val playPausePendingIntent = PendingIntent.getBroadcast(
            this, 2, playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = Intent(ACTION_NEXT)
        val nextPendingIntent = PendingIntent.getBroadcast(
            this, 3, nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val playPauseTitle = if (isPlaying) "Pause" else "Play"

        val builder = NotificationCompat.Builder(this, PLAYBACK_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(artist)
            .setSubText("EXOTIC MUSIC")
            .setColor(Color.parseColor("#FF7A00"))
            .setColorized(true)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(isPlaying)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(android.R.drawable.ic_media_previous, "Previous", prevPendingIntent)
            .addAction(playPauseIcon, playPauseTitle, playPausePendingIntent)
            .addAction(android.R.drawable.ic_media_next, "Next", nextPendingIntent)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0, 1, 2)
            )

        val notificationManager = NotificationManagerCompat.from(this)
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            notificationManager.notify(PLAYBACK_NOTIFICATION_ID, builder.build())
        }

        if (!coverUrl.isNullOrEmpty() && coverUrl.startsWith("http")) {
            thread {
                try {
                    val url = URL(coverUrl)
                    val conn = url.openConnection() as HttpURLConnection
                    conn.connectTimeout = 3000
                    conn.readTimeout = 3000
                    conn.doInput = true
                    conn.connect()
                    val input: InputStream = conn.inputStream
                    val bitmap: Bitmap? = BitmapFactory.decodeStream(input)
                    if (bitmap != null) {
                        builder.setLargeIcon(bitmap)
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                            notificationManager.notify(PLAYBACK_NOTIFICATION_ID, builder.build())
                        }
                    }
                } catch (_: Exception) {}
            }
        }
    }

    private fun hideMediaNotification() {
        val notificationManager = NotificationManagerCompat.from(this)
        notificationManager.cancel(PLAYBACK_NOTIFICATION_ID)
    }

    private fun showCustomNotification(id: Int, title: String, body: String) {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, id, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, ALERTS_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setColor(Color.parseColor("#FF7A00"))
            .setColorized(true)
            .setAutoCancel(true)
            .setContentIntent(openAppPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val notificationManager = NotificationManagerCompat.from(this)
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            notificationManager.notify(id, builder.build())
        }
    }

    private fun cancelNotification(id: Int) {
        val notificationManager = NotificationManagerCompat.from(this)
        notificationManager.cancel(id)
    }

    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == STORAGE_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        } else if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotifPermissionResult?.success(granted)
            pendingNotifPermissionResult = null
        }
    }

    private fun fetchMediaStoreAudio(): List<Map<String, Any>> {
        val audioList = mutableListOf<Map<String, Any>>()
        val uri: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor: Cursor? = contentResolver.query(uri, projection, selection, null, sortOrder)
        cursor?.use {
            val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val sizeCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)

            while (it.moveToNext()) {
                val id = it.getLong(idCol)
                val title = it.getString(titleCol) ?: "Unknown Track"
                val artist = it.getString(artistCol) ?: "Unknown Artist"
                val album = it.getString(albumCol) ?: "Unknown Album"
                val duration = it.getLong(durationCol)
                val path = it.getString(dataCol) ?: ""
                val size = it.getLong(sizeCol)

                if (path.isNotEmpty() && size > 40000) {
                    val item = mapOf(
                        "id" to "local_$id",
                        "title" to title,
                        "artist" to if (artist.contains("<unknown>", ignoreCase = true)) "Unknown Artist" else artist,
                        "album" to if (album.contains("<unknown>", ignoreCase = true)) "Unknown Album" else album,
                        "durationMs" to duration,
                        "path" to path,
                        "size" to size
                    )
                    audioList.add(item)
                }
            }
        }

        return audioList
    }
}
