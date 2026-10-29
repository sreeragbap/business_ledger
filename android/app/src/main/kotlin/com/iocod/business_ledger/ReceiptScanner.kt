package com.iocod.business_ledger

import android.app.Activity
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID

/**
 * Receipt scanning for `ReceiptScannerService` (Dart), on the device:
 *
 * - `capabilities` → `{camera: true}`
 * - `capture {source: "camera" | "photos"}` → path of a temporary JPEG in the
 *   cache, or null when the user backs out. "camera" opens ML Kit's document
 *   scanner (edge detection, crop, gallery import); "photos" the system
 *   photo picker. Neither needs a permission.
 * - `recognize {path}` → `[{text, left, top, right, bottom}]`, one entry per
 *   recognised line, boxes in image pixels.
 *
 * Built when the activity is constructed: activity-result launchers must be
 * registered before it starts.
 */
class ReceiptScanner(private val activity: ComponentActivity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "business_ledger/receipt_scanner"
    }

    private var pending: MethodChannel.Result? = null

    private val scanLauncher =
        activity.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            val uri =
                if (result.resultCode == Activity.RESULT_OK) {
                    GmsDocumentScanningResult.fromActivityResultIntent(result.data)
                        ?.pages
                        ?.firstOrNull()
                        ?.imageUri
                } else {
                    null
                }
            if (uri == null) {
                Thread { clearScannerCopies() }.start()
                finish(null)
            } else {
                copyToCache(uri, scanned = true)
            }
        }

    private val pickLauncher =
        activity.registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            if (uri == null) finish(null) else copyToCache(uri, scanned = false)
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> result.success(mapOf("camera" to true))
            "capture" -> capture(call.argument<String>("source"), result)
            "recognize" -> recognize(call.argument<String>("path"), result)
            else -> result.notImplemented()
        }
    }

    private fun capture(source: String?, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A scan is already open.", null)
            return
        }
        pending = result
        // Images an earlier scan left behind (the app closed mid-scan).
        Thread {
            activity.cacheDir.listFiles { file -> file.name.startsWith("receipt-") }
                ?.forEach { it.delete() }
            clearScannerCopies()
        }.start()
        if (source == "camera") {
            val options =
                GmsDocumentScannerOptions.Builder()
                    .setGalleryImportAllowed(true)
                    .setPageLimit(1)
                    .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                    .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                    .build()
            GmsDocumentScanning.getClient(options)
                .getStartScanIntent(activity)
                .addOnSuccessListener { sender ->
                    scanLauncher.launch(IntentSenderRequest.Builder(sender).build())
                }
                .addOnFailureListener { error -> fail("unavailable", error.message) }
        } else {
            pickLauncher.launch(
                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
            )
        }
    }

    /**
     * Copies the picked or scanned image into the app cache, off the main
     * thread. The document scanner keeps its own copy of each page in the
     * cache; that is deleted once copied.
     */
    private fun copyToCache(uri: Uri, scanned: Boolean) {
        Thread {
            try {
                val file = File(activity.cacheDir, "receipt-${UUID.randomUUID()}.jpg")
                val input =
                    activity.contentResolver.openInputStream(uri)
                        ?: throw IOException("Cannot open the image.")
                input.use { stream -> file.outputStream().use { stream.copyTo(it) } }
                activity.runOnUiThread { finish(file.absolutePath) }
            } catch (error: Exception) {
                activity.runOnUiThread { fail("capture-failed", error.message) }
            } finally {
                if (scanned) clearScannerCopies()
            }
        }.start()
    }

    /** Deletes the pages ML Kit's document scanner saved in the app cache. */
    private fun clearScannerCopies() {
        File(activity.cacheDir, "mlkit_docscan_ui_client").listFiles()?.forEach { it.deleteRecursively() }
    }

    private fun recognize(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("bad-args", "path is required", null)
            return
        }
        val image =
            try {
                InputImage.fromFilePath(activity, Uri.fromFile(File(path)))
            } catch (error: IOException) {
                result.error("recognize-failed", error.message, null)
                return
            }
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { text ->
                val lines =
                    text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                        val box = line.boundingBox ?: return@mapNotNull null
                        mapOf(
                            "text" to line.text,
                            "left" to box.left.toDouble(),
                            "top" to box.top.toDouble(),
                            "right" to box.right.toDouble(),
                            "bottom" to box.bottom.toDouble(),
                        )
                    }
                result.success(lines)
            }
            .addOnFailureListener { error -> result.error("recognize-failed", error.message, null) }
            .addOnCompleteListener { recognizer.close() }
    }

    private fun finish(path: String?) {
        pending?.success(path)
        pending = null
    }

    private fun fail(code: String, message: String?) {
        pending?.error(code, message, null)
        pending = null
    }
}
