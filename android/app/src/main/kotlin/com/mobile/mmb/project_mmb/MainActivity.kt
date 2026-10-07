package com.mobile.mmb.project_mmb

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.SegmentationMask
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import kotlin.math.min
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mobile.mmb.project_mmb/background_removal"
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val TAG = "BgRemoval"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "removeBackground" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        removeBackgroundFromImage(imagePath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun removeBackgroundFromImage(imagePath: String, result: MethodChannel.Result) {
        Log.d(TAG, "🎯 Starting BG removal: $imagePath")
        scope.launch {
            try {
                withTimeout(15000L) { // 15s timeout
                    val outputBytes = processImageOptimized(imagePath)
                    Handler(Looper.getMainLooper()).post {
                        Log.d(TAG, "✅ SUCCESS: ${outputBytes.size} bytes")
                        result.success(outputBytes)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                Log.e(TAG, "⏰ TIMEOUT after 15s")
                Handler(Looper.getMainLooper()).post { result.error("TIMEOUT", "Processing timeout", null) }
            } catch (e: Exception) {
                Log.e(TAG, "❌ ERROR: ${e.message}", e)
                Handler(Looper.getMainLooper()).post { result.error("ERROR", e.message, null) }
            }
        }
    }

    private suspend fun processImageOptimized(imagePath: String): ByteArray = withContext(Dispatchers.Default) {
        // 🔥 STEP 1: Load + Resize (512px max) = 3-5x faster
        val originalBitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw Exception("Failed to decode image")
        Log.d(TAG, "📐 Original: ${originalBitmap.width}x${originalBitmap.height}")

        val maxSize = 512
        val (processingBitmap, scaleX, scaleY) = if (originalBitmap.width > maxSize || originalBitmap.height > maxSize) {
            val ratio = min(maxSize.toFloat() / originalBitmap.width, maxSize.toFloat() / originalBitmap.height)
            val newW = (originalBitmap.width * ratio).toInt()
            val newH = (originalBitmap.height * ratio).toInt()
            Log.d(TAG, "🔄 Resizing to: $newW x $newH")
            Triple(
                Bitmap.createScaledBitmap(originalBitmap, newW, newH, true),
                originalBitmap.width.toFloat() / newW,
                originalBitmap.height.toFloat() / newH
            )
        } else Triple(originalBitmap, 1f, 1f)

        try {
            // 🔥 STEP 2: ML Kit Processing
            val processedSmall = processImageWithMLKit(processingBitmap)

            // 🔥 STEP 3: Scale back to original size
            val finalBitmap = if (scaleX != 1f || scaleY != 1f) {
                Log.d(TAG, "📏 Scaling back to original size")
                Bitmap.createScaledBitmap(processedSmall, originalBitmap.width, originalBitmap.height, true)
            } else processedSmall

            Log.d(TAG, "🎨 Final: ${finalBitmap.width}x${finalBitmap.height}")
            return@withContext bitmapToByteArray(finalBitmap)
        } finally {
            // 🔥 Memory cleanup
            if (processingBitmap != originalBitmap) processingBitmap.recycle()
        }
    }

    private suspend fun processImageWithMLKit(bitmap: Bitmap): Bitmap = withContext(Dispatchers.Default) {
        Log.d(TAG, "🤖 ML Kit processing ${bitmap.width}x${bitmap.height}")

        val options = SelfieSegmenterOptions.Builder()
            .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
            .build()

        val segmenter = Segmentation.getClient(options)
        val inputImage = InputImage.fromBitmap(bitmap, 0)

        // 🔥 FIXED: Proper suspendCoroutine usage
        val mask = suspendCoroutine<SegmentationMask> { continuation ->
            segmenter.process(inputImage)
                .addOnSuccessListener { segmentationMask ->
                    Log.d(TAG, "✅ ML Kit mask ready: ${segmentationMask.width}x${segmentationMask.height}")
                    continuation.resume(segmentationMask)
                }
                .addOnFailureListener { exception ->
                    Log.e(TAG, "❌ ML Kit failed: ${exception.message}")
                    continuation.resumeWithException(exception)
                }
        }

        applyMaskToBitmapFast(bitmap, mask)
    }

    // 🔥 ULTRA-FAST BULK PIXEL PROCESSING (10x faster than setPixel loop)
    private fun applyMaskToBitmapFast(
        original: Bitmap,
        mask: SegmentationMask
    ): Bitmap {

        val maskBuffer = mask.buffer
        val maskW = mask.width
        val maskH = mask.height

        val w = original.width
        val h = original.height

        Log.d(TAG, "🎭 Applying high-quality mask: ${w}x${h} -> ${maskW}x${maskH}")

        val output = Bitmap.createBitmap(
            w,
            h,
            Bitmap.Config.ARGB_8888
        )

        val originalPixels = IntArray(w * h)
        val outputPixels = IntArray(w * h)

        original.getPixels(
            originalPixels,
            0,
            w,
            0,
            0,
            w,
            h
        )

        val scaleX = maskW.toFloat() / w
        val scaleY = maskH.toFloat() / h

        for (y in 0 until h) {

            val maskY = (y * scaleY)
                .toInt()
                .coerceIn(0, maskH - 1)

            for (x in 0 until w) {

                val maskX = (x * scaleX)
                    .toInt()
                    .coerceIn(0, maskW - 1)

                val maskIndex =
                    (maskY * maskW + maskX) * 4

                maskBuffer.position(maskIndex)

                val confidence = maskBuffer.float

                /*
                 * Soft alpha:
                 *
                 * < 0.25  -> transparent
                 * 0.25-0.75 -> smooth transition
                 * > 0.75 -> fully visible
                 */
                val alpha = when {
                    confidence <= 0.25f -> {
                        0
                    }

                    confidence >= 0.75f -> {
                        255
                    }

                    else -> {
                        (
                                ((confidence - 0.25f) / 0.50f) * 255f
                                ).toInt().coerceIn(0, 255)
                    }
                }

                val pixel = originalPixels[y * w + x]

                outputPixels[y * w + x] =
                    Color.argb(
                        alpha,
                        Color.red(pixel),
                        Color.green(pixel),
                        Color.blue(pixel)
                    )
            }
        }

        output.setPixels(
            outputPixels,
            0,
            w,
            0,
            0,
            w,
            h
        )

        return output
    }

    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 95, stream) // Faster encoding
        return stream.toByteArray()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
