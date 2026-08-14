package com.quizsnap.quizsnap

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity : FlutterActivity() {

    private val CHANNEL = "quizsnap/folder"
    private val TAG = "QuizSnapFolder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "openFolder" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("invalid_arg", "path is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(openFolder(path))
                        }
                        "openTreeUri" -> {
                            val uri = call.argument<String>("uri")
                            if (uri == null) {
                                result.error("invalid_arg", "uri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(openTreeUri(uri))
                        }
                        "persistTreeUri" -> {
                            val uri = call.argument<String>("uri")
                            if (uri == null) {
                                result.error("invalid_arg", "uri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(persistTreeUri(uri))
                        }
                        "releaseTreeUri" -> {
                            val uri = call.argument<String>("uri")
                            if (uri == null) {
                                result.error("invalid_arg", "uri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(releaseTreeUri(uri))
                        }
                        "isTreeUriPersisted" -> {
                            val uri = call.argument<String>("uri")
                            if (uri == null) {
                                result.error("invalid_arg", "uri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(isTreeUriPersisted(uri))
                        }
                        "copyFileToTreeUri" -> {
                            val treeUri = call.argument<String>("treeUri")
                            val fileName = call.argument<String>("fileName")
                            val sourcePath = call.argument<String>("sourcePath")
                            if (treeUri == null || fileName == null || sourcePath == null) {
                                result.error("invalid_arg", "treeUri, fileName, sourcePath required", null)
                                return@setMethodCallHandler
                            }
                            result.success(copyFileToTreeUri(treeUri, fileName, sourcePath))
                        }
                        "listFilesInTreeUri" -> {
                            val treeUri = call.argument<String>("treeUri")
                            val extension = call.argument<String>("extension") ?: "db"
                            if (treeUri == null) {
                                result.error("invalid_arg", "treeUri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(listFilesInTreeUri(treeUri, extension))
                        }
                        "cacheFileFromTreeUri" -> {
                            val treeUri = call.argument<String>("treeUri")
                            val fileName = call.argument<String>("fileName")
                            if (treeUri == null || fileName == null) {
                                result.error("invalid_arg", "treeUri, fileName required", null)
                                return@setMethodCallHandler
                            }
                            result.success(cacheFileFromTreeUri(treeUri, fileName))
                        }
                        "deleteFileInTreeUri" -> {
                            val treeUri = call.argument<String>("treeUri")
                            val fileName = call.argument<String>("fileName")
                            if (treeUri == null || fileName == null) {
                                result.error("invalid_arg", "treeUri, fileName required", null)
                                return@setMethodCallHandler
                            }
                            result.success(deleteFileInTreeUri(treeUri, fileName))
                        }
                        "getFolderDisplayName" -> {
                            val treeUri = call.argument<String>("treeUri")
                            if (treeUri == null) {
                                result.error("invalid_arg", "treeUri is required", null)
                                return@setMethodCallHandler
                            }
                            result.success(getFolderDisplayName(treeUri))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "method ${call.method} failed", e)
                    result.error("native_error", e.message, null)
                }
            }
    }

    /**
     * Open an app-specific external storage folder using a FileProvider content URI.
     * Returns true if an intent was successfully launched.
     */
    private fun openFolder(path: String): Boolean {
        val folder = File(path)
        if (!folder.exists()) {
            folder.mkdirs()
        }

        // Try launching the file manager with a content URI via FileProvider.
        return try {
            val authority = "${packageName}.fileprovider"
            val uri = FileProvider.getUriForFile(this, authority, folder)
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, "vnd.android.document/directory")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Fallback: try opening with resource/folder mime type.
                intent.setDataAndType(uri, "resource/folder")
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    true
                } else {
                    // Final fallback: open the system Files/Downloads root.
                    openDownloadsRoot()
                }
            }
        } catch (e: IllegalArgumentException) {
            // FileProvider could not map the path; fall back to Downloads root.
            openDownloadsRoot()
        } catch (e: Exception) {
            Log.e(TAG, "openFolder failed", e)
            openDownloadsRoot()
        }
    }

    /**
     * Open the system Downloads directory as a last-resort fallback so the user
     * lands somewhere useful in a file manager.
     */
    private fun openDownloadsRoot(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(
                Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADownload"),
                "vnd.android.document/directory"
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Open a persisted SAF tree URI in the file manager.
     */
    private fun openTreeUri(uriString: String): Boolean {
        return try {
            val treeUri = Uri.parse(uriString)
            val docId = DocumentsContract.getTreeDocumentId(treeUri)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, docId)
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(childrenUri, "vnd.android.document/directory")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Fallback to viewing the tree uri directly.
                intent.setDataAndType(treeUri, "vnd.android.document/directory")
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    true
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "openTreeUri failed", e)
            false
        }
    }

    /**
     * Take a persistable URI permission so the SAF tree remains accessible after restart.
     */
    private fun persistTreeUri(uriString: String): Boolean {
        return try {
            val treeUri = Uri.parse(uriString)
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.takePersistableUriPermission(treeUri, flags)
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "persistTreeUri denied", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "persistTreeUri failed", e)
            false
        }
    }

    private fun releaseTreeUri(uriString: String): Boolean {
        return try {
            val treeUri = Uri.parse(uriString)
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.releasePersistableUriPermission(treeUri, flags)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isTreeUriPersisted(uriString: String): Boolean {
        return try {
            val treeUri = Uri.parse(uriString)
            contentResolver.persistedUriPermissions.any { it.uri == treeUri }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Copy a local file (sourcePath) into a SAF tree URI with the given fileName.
     * Overwrites an existing file with the same name. Returns the content URI of the
     * written file, or null on failure.
     */
    private fun copyFileToTreeUri(treeUriString: String, fileName: String, sourcePath: String): String? {
        var output: java.io.OutputStream? = null
        var input: FileInputStream? = null
        return try {
            val treeUri = Uri.parse(treeUriString)
            val tree = DocumentFile.fromTreeUri(this, treeUri) ?: return null
            // Remove existing file with the same name to overwrite.
            tree.findFile(fileName)?.delete()
            val newFile = tree.createFile("application/octet-stream", fileName) ?: return null
            input = FileInputStream(sourcePath)
            output = contentResolver.openOutputStream(newFile.uri)
            if (output == null) return null
            val buffer = ByteArray(8192)
            var read: Int
            while (input.read(buffer).also { read = it } != -1) {
                output.write(buffer, 0, read)
            }
            output.flush()
            newFile.uri.toString()
        } catch (e: Exception) {
            Log.e(TAG, "copyFileToTreeUri failed", e)
            null
        } finally {
            try { output?.close() } catch (_: IOException) {}
            try { input?.close() } catch (_: IOException) {}
        }
    }

    /**
     * List files (with the given extension) inside a SAF tree. Returns a list of maps:
     * {name, size, lastModified}.
     */
    private fun listFilesInTreeUri(treeUriString: String, extension: String): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        return try {
            val treeUri = Uri.parse(treeUriString)
            val tree = DocumentFile.fromTreeUri(this, treeUri) ?: return result
            for (doc in tree.listFiles()) {
                if (!doc.isFile) continue
                val name = doc.name ?: continue
                if (!name.endsWith(".$extension", ignoreCase = true)) continue
                result.add(
                    mapOf(
                        "name" to name,
                        "size" to doc.length(),
                        "lastModified" to doc.lastModified()
                    )
                )
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "listFilesInTreeUri failed", e)
            result
        }
    }

    /**
     * Copy a file from a SAF tree into the app cache so it can be shared/opened.
     * Returns the cached file path, or null on failure.
     */
    private fun cacheFileFromTreeUri(treeUriString: String, fileName: String): String? {
        var input: java.io.InputStream? = null
        var output: java.io.FileOutputStream? = null
        return try {
            val treeUri = Uri.parse(treeUriString)
            val tree = DocumentFile.fromTreeUri(this, treeUri) ?: return null
            val file = tree.findFile(fileName) ?: return null
            input = contentResolver.openInputStream(file.uri) ?: return null
            val cacheFile = File(cacheDir, fileName)
            output = java.io.FileOutputStream(cacheFile)
            val buffer = ByteArray(8192)
            var read: Int
            while (input.read(buffer).also { read = it } != -1) {
                output.write(buffer, 0, read)
            }
            output.flush()
            cacheFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "cacheFileFromTreeUri failed", e)
            null
        } finally {
            try { output?.close() } catch (_: IOException) {}
            try { input?.close() } catch (_: IOException) {}
        }
    }

    private fun deleteFileInTreeUri(treeUriString: String, fileName: String): Boolean {
        return try {
            val treeUri = Uri.parse(treeUriString)
            val tree = DocumentFile.fromTreeUri(this, treeUri) ?: return false
            val file = tree.findFile(fileName) ?: return false
            file.delete()
        } catch (e: Exception) {
            false
        }
    }

    private fun getFolderDisplayName(treeUriString: String): String? {
        return try {
            val treeUri = Uri.parse(treeUriString)
            val tree = DocumentFile.fromTreeUri(this, treeUri) ?: return null
            tree.name
        } catch (e: Exception) {
            null
        }
    }
}
