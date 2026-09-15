package com.mysticcat.journal

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder

/** User-started playback controls; media and diary data remain in Flutter. */
class MeditationPlaybackService : Service() {
    companion object {
        var command: ((String) -> Unit)? = null
        var instance: MeditationPlaybackService? = null
        const val STOP = "garden.meditation.STOP"
        const val PLAY = "garden.meditation.PLAY"
        const val PAUSE = "garden.meditation.PAUSE"
    }
    private lateinit var session: MediaSession
    private var title = "마음냥 정원 명상"
    private var playing = true
    override fun onCreate() {
        super.onCreate()
        instance = this
        session = MediaSession(this, "GardenMeditation")
        session.setCallback(object : MediaSession.Callback() {
            override fun onPlay() { command?.invoke("play") }
            override fun onPause() { command?.invoke("pause") }
            override fun onStop() { command?.invoke("stop"); stopSelf() }
        })
        session.isActive = true
        if (Build.VERSION.SDK_INT >= 26) getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel("garden_meditation_playback", "명상 재생", NotificationManager.IMPORTANCE_LOW))
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when(intent?.action) {
            STOP -> { command?.invoke("stop"); stopSelf(); return START_NOT_STICKY }
            PLAY -> command?.invoke("play")
            PAUSE -> command?.invoke("pause")
        }
        render()
        return START_NOT_STICKY
    }
    fun update(name: String, active: Boolean, position: Long, duration: Long, speed: Float) {
        title = name; playing = active
        session.setMetadata(MediaMetadata.Builder().putString(MediaMetadata.METADATA_KEY_TITLE,title)
            .putString(MediaMetadata.METADATA_KEY_ARTIST,"마음냥 정원")
            .putLong(MediaMetadata.METADATA_KEY_DURATION,duration).build())
        session.setPlaybackState(PlaybackState.Builder()
            .setActions(PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_STOP or PlaybackState.ACTION_PLAY_PAUSE)
            .setState(if(active) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,position,if(active) speed else 0f).build())
        render()
    }
    private fun render() {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun action(code: Int, name: String) = PendingIntent.getService(this, code,
            Intent(this, MeditationPlaybackService::class.java).setAction(name), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this,"garden_meditation_playback") else Notification.Builder(this)
        val notification = builder.setContentTitle(title).setContentText(if(playing) "명상 재생 중" else "명상 일시정지")
            .setSmallIcon(android.R.drawable.ic_media_play).setContentIntent(open).setOngoing(playing)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(if(playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if(playing) "일시정지" else "재생",action(1,if(playing) PAUSE else PLAY))
            .addAction(android.R.drawable.ic_menu_close_clear_cancel,"종료",action(2,STOP))
            .setStyle(Notification.MediaStyle().setMediaSession(session.sessionToken).setShowActionsInCompactView(0,1)).build()
        if (Build.VERSION.SDK_INT >= 29) startForeground(7318,notification,ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        else startForeground(7318,notification)
    }
    override fun onTaskRemoved(rootIntent: Intent?) {command?.invoke("stop");stopSelf();super.onTaskRemoved(rootIntent)}
    override fun onDestroy() { instance=null; session.isActive=false;session.release();stopForeground(true);super.onDestroy() }
}
