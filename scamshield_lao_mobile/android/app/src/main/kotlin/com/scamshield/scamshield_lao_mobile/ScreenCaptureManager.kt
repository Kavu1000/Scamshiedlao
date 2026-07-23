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
 * one full-device-screen frame per [captureOnce] call. The projection and its
 * single [VirtualDisplay] are reused for the whole consent session; only the
 * per-capture [ImageReader] surface is replaced after each shot.
 */
object ScreenCaptureManager {
    @Volatile
    private var mediaProjection: MediaProjection? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var activeImageReader: ImageReader? = null
    private var captureInProgress = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            releaseCaptureResources()
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
        releaseCaptureResources()
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

        bgHandler.post {
            if (mediaProjection !== projection || captureInProgress) {
                onResult(null)
                return@post
            }
            captureInProgress = true

            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                .defaultDisplay
                .getRealMetrics(metrics)
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            val imageReader = ImageReader.newInstance(
                width,
                height,
                android.graphics.PixelFormat.RGBA_8888,
                2
            )
            activeImageReader = imageReader

            // Android 14 allows createVirtualDisplay() only once for each
            // MediaProjection consent token. Keep that display for the whole
            // sharing session and swap its ImageReader surface for each scan.
            val delivered = java.util.concurrent.atomic.AtomicBoolean(false)
            imageReader.setOnImageAvailableListener({ reader ->
                if (!delivered.compareAndSet(false, true)) return@setOnImageAvailableListener

                var image: Image? = null
                var path: String? = null
                try {
                    image = reader.acquireLatestImage()
                    path = image?.let { saveImageAsPng(context, it, width, height) }
                } catch (e: Exception) {
                    Log.e(TAG, "capture failed", e)
                } finally {
                    image?.close()
                    finishCapture(reader)
                    onResult(path)
                }
            }, bgHandler)

            try {
                val display = virtualDisplay
                if (display == null) {
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
                } else {
                    display.setSurface(imageReader.surface)
                }
            } catch (e: Exception) {
                Log.e(TAG, "starting screen capture failed", e)
                finishCapture(imageReader)
                onResult(null)
            }
        }
    }

    /** Detaches and closes only the per-scan surface, preserving the display. */
    private fun finishCapture(reader: ImageReader) {
        if (activeImageReader !== reader) return
        try {
            virtualDisplay?.setSurface(null)
        } catch (e: Exception) {
            Log.w(TAG, "detaching capture surface failed", e)
        }
        reader.setOnImageAvailableListener(null, null)
        reader.close()
        activeImageReader = null
        captureInProgress = false
    }

    private fun releaseCaptureResources() {
        activeImageReader?.let { reader ->
            reader.setOnImageAvailableListener(null, null)
            reader.close()
        }
        activeImageReader = null
        virtualDisplay?.release()
        virtualDisplay = null
        captureInProgress = false
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
