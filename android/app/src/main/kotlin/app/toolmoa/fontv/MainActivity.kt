package app.toolmoa.fontv

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Typeface
import android.graphics.fonts.Font
import android.graphics.fonts.FontFamily
import android.graphics.fonts.FontStyle
import android.graphics.fonts.SystemFonts
import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val faces = linkedMapOf<String, Font>()
    private val coverage = mutableMapOf<String, CmapCoverage>()
    private var saveResult: MethodChannel.Result? = null
    private var saveBytes: ByteArray? = null
    private val importDirectory get() = File(filesDir, "fontv-imports").apply { mkdirs() }
    private val typefaces = object : LinkedHashMap<String, Typeface>(32, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Typeface>?) = size > 32
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.toolmoa.fontv/fonts")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImage") {
                    saveImage(call, result)
                    return@setMethodCallHandler
                }
                if (call.method == "inspectNativeAdMedia" &&
                    (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                    val media = mutableListOf<Map<String, Any>>()
                    fun inspect(view: View) {
                        if (view.javaClass.name == "com.google.android.gms.ads.nativead.MediaView") {
                            val density = resources.displayMetrics.density
                            media.add(mapOf("width" to view.width / density,
                                "height" to view.height / density,
                                "visible" to view.isShown))
                        }
                        if (view is ViewGroup) for (index in 0 until view.childCount) inspect(view.getChildAt(index))
                    }
                    inspect(window.decorView)
                    result.success(media)
                    return@setMethodCallHandler
                }
                // Serial background work bounds bitmap memory and keeps scrolling off the UI thread.
                worker.execute {
                    try {
                        val value = when (call.method) {
                            "getFonts" -> getFonts()
                            "renderPreview" -> render(call)
                            "getHangulFonts" -> faces.keys.filter {
                                try { coverageFor(it).supportsHangul() } catch (_: Exception) { false }
                            }
                            "checkGlyphs" -> {
                                val cmap = coverageFor(requireNotNull(call.argument<String>("fontId")))
                                (call.argument<List<Number>>("codePoints") ?: emptyList()).take(1000)
                                    .map { it.toInt() }.filter { !cmap.hasGlyph(it) }
                            }
                            "importFont" -> importFont(call)
                            "removeImportedFont" -> removeImportedFont(call)
                            else -> { main.post { result.notImplemented() }; return@execute }
                        }
                        main.post { result.success(value) }
                    } catch (error: Exception) {
                        val code = if (error is FontOperationError) error.code else "FONT_ERROR"
                        main.post { result.error(code, error.message, null) }
                    }
                }
            }
    }

    private fun getFonts(): List<Map<String, Any>> {
        faces.clear()
        typefaces.clear()
        coverage.clear()
        val system = SystemFonts.getAvailableFonts().mapNotNull { font ->
            val file = font.file ?: return@mapNotNull null
            val axes = font.axes?.joinToString(",") { "${it.tag}=${it.styleValue}" } ?: ""
            val id = "${file.absolutePath}#${font.ttcIndex}#${font.style.weight}#${font.style.slant}#$axes"
            val names = readNames(font.buffer, font.ttcIndex)
            val family = names[16] ?: names[1] ?: file.nameWithoutExtension
            val style = names[17] ?: names[2] ?: "${font.style.weight}"
            val name = names[6] ?: names[4] ?: "$family $style"
            faces[id] = font
            mapOf("id" to id, "name" to name, "family" to family,
                "style" to "$style · ${font.style.weight}${if (font.style.slant == FontStyle.FONT_SLANT_ITALIC) " · Italic" else ""}", "imported" to false)
        }
        val imported = importDirectory.listFiles()?.filter { it.extension == "font" && it.length() <= 32L * 1024 * 1024 }?.mapNotNull { file ->
            try { importedFace(file) } catch (_: Exception) { null }
        } ?: emptyList()
        return (system + imported).distinctBy { it["id"] }.sortedWith(compareBy({ it["family"].toString() }, { it["name"].toString() }))
    }

    private class FontOperationError(val code: String) : Exception(code)
    private fun coverageFor(id: String): CmapCoverage = coverage.getOrPut(id) {
        val font = requireNotNull(faces[id]) { "Unknown font" }
        CmapCoverage(font.buffer, font.ttcIndex)
    }
    private fun importedFace(file: File): Map<String, Any> {
        val font = Font.Builder(file).build()
        val id = "import:${file.nameWithoutExtension}"
        val names = readNames(font.buffer, 0)
        val family = names[16] ?: names[1] ?: "Imported font"
        faces[id] = font
        return mapOf("id" to id, "name" to (names[6] ?: names[4] ?: family),
            "family" to family, "style" to (names[17] ?: names[2] ?: "Regular"), "imported" to true)
    }
    private fun importFont(call: MethodCall): Map<String, Any> {
        val bytes = call.argument<ByteArray>("bytes") ?: throw FontOperationError("FONT_INVALID")
        if (bytes.size > 32 * 1024 * 1024) throw FontOperationError("FONT_TOO_LARGE")
        if (bytes.size < 12 || ByteBuffer.wrap(bytes).getInt(0) !in setOf(0x00010000, 0x4f54544f, 0x74727565)) throw FontOperationError("FONT_INVALID")
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
        val target = File(importDirectory, "$digest.font")
        if (target.exists()) return importedFace(target)
        val files = importDirectory.listFiles()?.filter { it.extension == "font" } ?: emptyList()
        if (files.size >= 50 || files.sumOf { it.length() } + bytes.size > 100L * 1024 * 1024) throw FontOperationError("FONT_LIMIT")
        val pending = File.createTempFile("import-", ".tmp", importDirectory)
        try {
            pending.writeBytes(bytes)
            try {
                val font = Font.Builder(pending).build()
                CmapCoverage(font.buffer, 0)
            } catch (_: Exception) { throw FontOperationError("FONT_INVALID") }
            if (!pending.renameTo(target)) throw FontOperationError("FONT_WRITE")
            return importedFace(target)
        } finally { pending.delete() }
    }
    private fun removeImportedFont(call: MethodCall): Any? {
        val id = call.argument<String>("fontId") ?: throw FontOperationError("FONT_INVALID")
        if (!Regex("import:[0-9a-f]{64}").matches(id)) throw FontOperationError("FONT_INVALID")
        val file = File(importDirectory, "${id.removePrefix("import:")}.font")
        if (file.exists() && !file.delete()) throw FontOperationError("FONT_WRITE")
        faces.remove(id); coverage.remove(id); typefaces.remove(id)
        return null
    }

    @Suppress("DEPRECATION")
    private fun saveImage(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null || bytes.size > 32 * 1024 * 1024 || bytes.size < 8 ||
            !bytes.take(8).toByteArray().contentEquals(byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47, 13, 10, 26, 10))) {
            result.error("IMAGE_INVALID", "Invalid PNG", null); return
        }
        if (saveResult != null) { result.error("IMAGE_BUSY", "Save is already open", null); return }
        saveResult = result; saveBytes = bytes
        try {
            startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/png"
                putExtra(Intent.EXTRA_TITLE, (call.argument<String>("filename") ?: "FontV.png").replace(Regex("[/\\\\]"), "_"))
            }, 0x5f70)
        } catch (error: Exception) {
            saveResult = null; saveBytes = null
            result.error("IMAGE_SAVE", error.message, null)
        }
    }
    @Deprecated("Android activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 0x5f70) return
        val pending = saveResult ?: return
        val bytes = saveBytes
        saveResult = null; saveBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) { pending.success(false); return }
        worker.execute {
            try {
                requireNotNull(contentResolver.openOutputStream(uri, "wt")).use { it.write(bytes) }
                main.post { pending.success(true) }
            } catch (error: Exception) { main.post { pending.error("IMAGE_SAVE", error.message, null) } }
        }
    }

    private fun render(call: MethodCall): ByteArray {
        val id = requireNotNull(call.argument<String>("fontId"))
        val font = requireNotNull(faces[id]) { "Unknown font" }
        fun number(key: String) = requireNotNull(call.argument<Number>(key)).toDouble()
        val width = number("width").coerceIn(1.0, 1600.0)
        val height = number("height").coerceIn(1.0, 1600.0)
        val scale = number("scale").coerceIn(1.0, 3.0)
        val size = number("size").coerceIn(8.0, 120.0)
        val sourceText = call.argument<String>("text") ?: ""
        val text = sourceText.substring(0, sourceText.offsetByCodePoints(0,
            sourceText.codePointCount(0, sourceText.length).coerceAtMost(1000)))
        val typeface = typefaces.getOrPut(id) {
            Typeface.CustomFallbackBuilder(FontFamily.Builder(font).build())
                .setStyle(font.style).setSystemFallback("sans-serif").build()
        }
        val bitmap = Bitmap.createBitmap((width * scale).toInt().coerceAtLeast(1),
            (height * scale).toInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.scale(scale.toFloat(), scale.toFloat())
            val paint = TextPaint(TextPaint.ANTI_ALIAS_FLAG or TextPaint.SUBPIXEL_TEXT_FLAG).apply {
                this.typeface = typeface
                textSize = size.toFloat()
                color = number("color").toLong().toInt()
                letterSpacing = ((call.argument<Number>("letterSpacing")?.toDouble() ?: 0.0).coerceIn(-2.0, 12.0) / size).toFloat()
            }
            val alignment = when (call.argument<String>("alignment")) {
                "center" -> Layout.Alignment.ALIGN_CENTER
                "right" -> Layout.Alignment.ALIGN_OPPOSITE
                else -> Layout.Alignment.ALIGN_NORMAL
            }
            val layout = StaticLayout.Builder.obtain(text, 0, text.length, paint, width.toInt().coerceAtLeast(1))
                .setAlignment(alignment).setIncludePad(false)
                .setTextDirection(android.text.TextDirectionHeuristics.LTR)
                .setLineSpacing(0f, (call.argument<Number>("lineHeight")?.toFloat() ?: 1.35f).coerceIn(1f, 2.5f)).build()
            layout.draw(canvas)
            return ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            }
        } finally { bitmap.recycle() }
    }

    /** Read the OpenType names at the correct TTC index, without a filename heuristic.
     * Prefer English Unicode records for stable searchable names across locales. */
    private fun readNames(source: ByteBuffer, ttcIndex: Int): Map<Int, String> {
        return try {
            val buffer = source.duplicate().order(ByteOrder.BIG_ENDIAN)
            fun u16(offset: Int) = buffer.getShort(offset).toInt() and 0xffff
            val offset = if (buffer.getInt(0) == 0x74746366) buffer.getInt(12 + ttcIndex * 4) else 0
            val tables = u16(offset + 4)
            var nameTable = -1
            for (index in 0 until tables) {
                val record = offset + 12 + index * 16
                if (buffer.getInt(record) == 0x6e616d65) {
                    nameTable = buffer.getInt(record + 8)
                    break
                }
            }
            if (nameTable < 0) return emptyMap()
            val count = u16(nameTable + 2)
            val strings = nameTable + u16(nameTable + 4)
            val names = mutableMapOf<Int, Pair<Int, String>>()
            for (index in 0 until count) {
                val record = nameTable + 6 + index * 12
                val platform = u16(record)
                val language = u16(record + 4)
                val nameId = u16(record + 6)
                if (nameId !in setOf(1, 2, 4, 6, 16, 17)) continue
                val length = u16(record + 8)
                val start = strings + u16(record + 10)
                if (length <= 0 || start < 0 || start.toLong() + length > buffer.limit()) continue
                val bytes = ByteArray(length)
                buffer.position(start)
                buffer.get(bytes)
                val charset = if (platform == 0 || platform == 3) Charsets.UTF_16BE else Charsets.ISO_8859_1
                val value = String(bytes, charset).replace("\u0000", "").trim()
                val score = if (platform == 3 && language == 0x409) 3 else if (platform == 0) 2 else 1
                if (value.isNotEmpty() && score > (names[nameId]?.first ?: 0)) names[nameId] = score to value
            }
            names.mapValues { it.value.second }
        } catch (_: Exception) { emptyMap() }
    }

    override fun onDestroy() { worker.shutdown(); super.onDestroy() }
}
