package com.scamshield.scamshield_lao_mobile

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * flutter_overlay_window's own shareData/overlayListener bridge only reliably
 * relays main-app -> overlay messages (verified empirically); messages sent
 * from the overlay isolate never reach the main isolate. [bridgeChannelName]
 * is our own direct channel to carry the overlay bubble's tap signal back to
 * the main isolate, bypassing that one-way limitation.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.scamshield.scamshield_lao_mobile/screen_capture"
    private val bridgeChannelName = "com.scamshield.scamshield_lao_mobile/overlay_bridge"
    private val overlayEngineCacheTag = "myCachedEngine"
    private val projectionRequestCode = 4200
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var mainBridgeChannel: MethodChannel? = null
    private var overlayBridgeWired = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    pendingPermissionResult = result
                    val manager =
                        getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(manager.createScreenCaptureIntent(), projectionRequestCode)
                }
                "capture" -> {
                    ScreenCaptureManager.captureOnce(applicationContext) { path ->
                        mainHandler.post { result.success(path) }
                    }
                }
                "isActive" -> result.success(ScreenCaptureManager.isActive)
                "stopProjection" -> {
                    stopService(Intent(this, ScreenCaptureService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        mainBridgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, bridgeChannelName)
        pollForOverlayEngine()
    }

    /** The overlay's FlutterEngine is created lazily once the bubble is shown; poll until it's cached. */
    private fun pollForOverlayEngine() {
        if (overlayBridgeWired) return
        val overlayEngine = FlutterEngineCache.getInstance().get(overlayEngineCacheTag)
        if (overlayEngine == null) {
            mainHandler.postDelayed({ pollForOverlayEngine() }, 300)
            return
        }
        overlayBridgeWired = true
        MethodChannel(overlayEngine.dartExecutor.binaryMessenger, bridgeChannelName).setMethodCallHandler { call, result ->
            // Relay every overlay-isolate signal (triggerScan, closeResult, ...)
            // to the main isolate, which owns the scan + overlay lifecycle.
            mainBridgeChannel?.invokeMethod(call.method, call.arguments)
            result.success(null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == projectionRequestCode) {
            val granted = resultCode == Activity.RESULT_OK && data != null
            if (granted) {
                val serviceIntent = ScreenCaptureService.buildStartIntent(this, resultCode, data!!)
                ContextCompat.startForegroundService(this, serviceIntent)
            }
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
