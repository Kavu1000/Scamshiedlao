package com.scamshield.scamshield_lao_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that must be alive (with foregroundServiceType="mediaProjection")
 * before ScreenCaptureManager is allowed to start/use its MediaProjection token —
 * required by the platform since Android 14. Holds no state itself; all capture
 * logic lives in ScreenCaptureManager so MainActivity's MethodChannel can call it
 * directly from the same process.
 */
class ScreenCaptureService : Service() {

    companion object {
        const val CHANNEL_ID = "scamshield_screen_capture"
        const val NOTIFICATION_ID = 4201
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"

        fun buildStartIntent(context: android.content.Context, resultCode: Int, data: Intent): Intent {
            return Intent(context, ScreenCaptureService::class.java).apply {
                putExtra(EXTRA_RESULT_CODE, resultCode)
                putExtra(EXTRA_DATA, data)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Int.MIN_VALUE as the "extra missing" sentinel — RESULT_OK is -1, so
        // using -1 as the sentinel would mistake a legitimate success code for "missing".
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, Int.MIN_VALUE) ?: Int.MIN_VALUE
        @Suppress("DEPRECATION")
        val data = intent?.getParcelableExtra<Intent>(EXTRA_DATA)
        if (resultCode != Int.MIN_VALUE && data != null) {
            ScreenCaptureManager.start(applicationContext, resultCode, data)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        ScreenCaptureManager.stop()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Scam scanning",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Active while the floating scan bubble can read on-screen content"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification() =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ScamShield Lao")
            .setContentText("Floating scan is active — tap the bubble to check on-screen text")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .build()
}
