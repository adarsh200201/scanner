package com.adarsh.pdfscanner

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "proscan.gallery"
    private val REQ_WRITE_STORAGE = 1001
    private var pendingPath: String? = null
    private var pendingTitle: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImage") {
                val path = call.argument<String>("path")
                val title = call.argument<String>("title") ?: "Image"
                if (path == null) {
                    result.error("ARG", "Missing path", null)
                    return@setMethodCallHandler
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    val hasWrite = ActivityCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
                    if (!hasWrite) {
                        pendingPath = path
                        pendingTitle = title
                        pendingResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE), REQ_WRITE_STORAGE)
                        return@setMethodCallHandler
                    }
                }

                try {
                    val ok = saveImageToGallery(path, title)
                    result.success(ok)
                } catch (e: Exception) {
                    result.error("ERR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_WRITE_STORAGE) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            val path = pendingPath
            val title = pendingTitle
            val res = pendingResult
            pendingPath = null
            pendingTitle = null
            pendingResult = null
            if (granted && path != null && title != null && res != null) {
                try {
                    val ok = saveImageToGallery(path, title)
                    res.success(ok)
                } catch (e: Exception) {
                    res.error("ERR", e.message, null)
                }
            } else {
                res?.error("PERM", "Storage permission denied", null)
            }
        }
    }

    private fun saveImageToGallery(srcPath: String, title: String): Boolean {
        val srcFile = if (srcPath.startsWith("file://")) File(android.net.Uri.parse(srcPath).path!!) else File(srcPath)
        if (!srcFile.exists()) return false
        val mime = when {
            srcPath.lowercase().endsWith(".png") -> "image/png"
            else -> "image/jpeg"
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, srcFile.name)
                put(MediaStore.Images.Media.MIME_TYPE, mime)
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/ProScan")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(srcFile).use { input ->
                    input.copyTo(out)
                }
            }
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            true
        } else {
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES + "/ProScan")
            if (!dir.exists()) dir.mkdirs()
            val dest = File(dir, srcFile.name)
            FileInputStream(srcFile).use { input ->
                FileOutputStream(dest).use { output ->
                    input.copyTo(output)
                }
            }
            true
        }
    }
}
