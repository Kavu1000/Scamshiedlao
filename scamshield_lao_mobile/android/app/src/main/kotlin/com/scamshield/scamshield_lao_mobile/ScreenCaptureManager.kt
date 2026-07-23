package com.scamshield.scamshield_lao_mobile

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import java.io.File
import java.io.FileOutputStream

private const val TAG = "ScreenCaptureManager"

/**
 * Holds the single [MediaProjection] token for the app's lifetime and grabs
 * one full-device-screen frame per [captureOnce] call. The projection itself
 * is created once (per user consent) and reused across captures — only the
 * per-capture [ImageReader]/[VirtualDisplay] pair is torn down after each shot.
 */
object ScreenCaptureManager {
    private var mediaProjection: MediaProjection? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            mediaProjection = null
        }
    }

    val isActive: Boolean
        get() = mediaProjection != null

    fun start(context: Context, resultCode: Int, data: Intent) {
        var thread = handlerThread
        if (thread == null) {
            thread = HandlerThread("ScreenCaptureThread").also { it.start() }
            handlerThread = thread
            handler = Handler(thread.looper)
        }
        val manager =
            context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection = manager.getMediaProjection(resultCode, data) ?: return
        projection.registerCallback(projectionCallback, handler!!)
        mediaProjection = projection
    }

    fun stop() {
        mediaProjection?.unregisterCallback(projectionCallback)
        mediaProjection?.stop()
        mediaProjection = null
        handlerThread?.quitSafely()
        handlerThread = null
        handler = null
    }

    /**
     * Captures exactly one frame of the current physical display (whatever app is
     * on top) and writes it to a PNG in the app's cache dir. Invokes [onResult] with
     * the file path, or null on any failure. [onResult] fires on the calling thread's
     * looper via the capture handler thread — callers must hop back to main themselves.
     */
    fun captureOnce(context: Context, onResult: (String?) -> Unit) {
        val projection = mediaProjection
        val bgHandler = handler
        if (projection == null || bgHandler == null) {
            onResult(null)
            return
        }

        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
            .defaultDisplay
            .getRealMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val imageReader = ImageReader.newInstance(width, height, android.graphics.PixelFormat.RGBA_8888, 2)
        var virtualDisplay: VirtualDisplay? = null
        // VirtualDisplay can deliver more than one buffered frame before teardown
        // takes effect; onResult (and the Flutter Result it completes) must fire
        // exactly once, so subsequent onImageAvailable callbacks are ignored.
        val delivered = java.util.concurrent.atomic.AtomicBoolean(false)

        imageReader.setOnImageAvailableListener({ reader ->
            var image: Image? = null
            try {
                image = reader.acquireLatestImage()
                if (delivered.compareAndSet(false, true)) {
                    val path = image?.let { saveImageAsPng(context, it, width, height) }
                    virtualDisplay?.release()
                    imageReader.close()
                    onResult(path)
                }
            } catch (e: Exception) {
                Log.e(TAG, "capture failed", e)
                if (delivered.compareAndSet(false, true)) onResult(null)
            } finally {
                image?.close()
            }
        }, bgHandler)

        try {
            virtualDisplay = projection.createVirtualDisplay(
                "ScamShieldCapture",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader.surface,
                null,
                bgHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "createVirtualDisplay failed", e)
            onResult(null)
        }
    }

    private fun saveImageAsPng(context: Context, image: Image, width: Int, height: Int): String {
        val plane = image.planes[0]
        val buffer = plane.buffer
        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        val rowPadding = rowStride - pixelStride * width

        val bitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        val cropped = Bitmap.createBitmap(bitmap, 0, 0, width, height)

        val file = File(context.cacheDir, "scamshield_capture_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            cropped.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        bitmap.recycle()
        cropped.recycle()
        return file.absolutePath
    }
}
