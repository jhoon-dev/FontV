package com.isdow.apps.font_v

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Typeface
import android.graphics.fonts.Font
import android.graphics.fonts.FontFamily
import android.graphics.fonts.FontStyle
import android.graphics.fonts.SystemFonts
import android.os.Handler
import android.os.Looper
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
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val faces = linkedMapOf<String, Font>()
    private val typefaces = object : LinkedHashMap<String, Typeface>(32, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Typeface>?) = size > 32
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.isdow.fontv/fonts")
            .setMethodCallHandler { call, result ->
                // Serial background work bounds bitmap memory and keeps scrolling off the UI thread.
                worker.execute {
                    try {
                        val value = when (call.method) {
                            "getFonts" -> getFonts()
                            "renderPreview" -> render(call)
                            else -> { main.post { result.notImplemented() }; return@execute }
                        }
                        main.post { result.success(value) }
                    } catch (error: Exception) {
                        main.post { result.error("FONT_ERROR", error.message, null) }
                    }
                }
            }
    }

    private fun getFonts(): List<Map<String, String>> {
        faces.clear()
        typefaces.clear()
        return SystemFonts.getAvailableFonts().mapNotNull { font ->
            val file = font.file ?: return@mapNotNull null
            val axes = font.axes?.joinToString(",") { "${it.tag}=${it.styleValue}" } ?: ""
            val id = "${file.absolutePath}#${font.ttcIndex}#${font.style.weight}#${font.style.slant}#$axes"
            val names = readNames(font.buffer, font.ttcIndex)
            val family = names[16] ?: names[1] ?: file.nameWithoutExtension
            val style = names[17] ?: names[2] ?: "${font.style.weight}"
            val name = names[6] ?: names[4] ?: "$family $style"
            faces[id] = font
            mapOf("id" to id, "name" to name, "family" to family,
                "style" to "$style · ${font.style.weight}${if (font.style.slant == FontStyle.FONT_SLANT_ITALIC) " · Italic" else ""}")
        }.distinctBy { it["id"] }.sortedWith(compareBy({ it["family"] }, { it["name"] }))
    }

    private fun render(call: MethodCall): ByteArray {
        val id = requireNotNull(call.argument<String>("fontId"))
        val font = requireNotNull(faces[id]) { "Unknown font" }
        fun number(key: String) = requireNotNull(call.argument<Number>(key)).toDouble()
        val width = number("width").coerceIn(1.0, 1600.0)
        val height = number("height").coerceIn(1.0, 1600.0)
        val scale = number("scale").coerceIn(1.0, 3.0)
        val size = number("size").coerceIn(8.0, 120.0)
        val text = (call.argument<String>("text") ?: "").take(1000)
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
            }
            val layout = StaticLayout.Builder.obtain(text, 0, text.length, paint, width.toInt().coerceAtLeast(1))
                .setAlignment(Layout.Alignment.ALIGN_NORMAL).setIncludePad(false)
                .setLineSpacing(0f, 1.35f).build()
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
