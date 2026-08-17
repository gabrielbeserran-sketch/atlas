package br.com.projetoatlas.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "br.com.projetoatlas.app/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val path = call.argument<String>("path").orEmpty()
                    openFile(path, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openFile(rawPath: String, result: MethodChannel.Result) {
        try {
            val file = File(rawPath).canonicalFile
            if (!file.isFile) {
                result.error("file_not_found", "Arquivo não localizado.", null)
                return
            }

            val allowedRoots = buildList {
                add(cacheDir.canonicalFile)
                add(filesDir.canonicalFile)
                externalCacheDir?.canonicalFile?.let { add(it) }
            }
            val allowed = allowedRoots.any { root ->
                file.path == root.path ||
                    file.path.startsWith(root.path + File.separator)
            }
            if (!allowed) {
                result.error(
                    "file_outside_app_storage",
                    "Arquivo fora do cache privado do Atlas.",
                    null,
                )
                return
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file,
            )
            val mime = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(file.extension.lowercase())
                ?: "application/octet-stream"

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(Intent.createChooser(intent, "Abrir documento"))
            result.success(true)
        } catch (error: ActivityNotFoundException) {
            result.error("no_handler", "Nenhum aplicativo compatível.", null)
        } catch (error: Exception) {
            result.error(
                "open_failed",
                error.message ?: "Falha ao abrir arquivo.",
                null,
            )
        }
    }
}
