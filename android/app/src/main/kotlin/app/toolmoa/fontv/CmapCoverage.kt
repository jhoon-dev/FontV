package app.toolmoa.fontv

import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Reads the selected face's own Unicode cmap. Never consults Android fallback fonts. */
internal class CmapCoverage(source: ByteBuffer, faceIndex: Int) {
    private val data = source.duplicate().order(ByteOrder.BIG_ENDIAN)
    private data class Subtable(val offset: Int, val length: Int, val format: Int)
    private val subtables = mutableListOf<Subtable>()
    private var glyphCount = 65536

    private fun u16(offset: Int): Int {
        require(offset >= 0 && offset.toLong() + 2 <= data.limit())
        return data.getShort(offset).toInt() and 0xffff
    }
    private fun u32(offset: Int): Long {
        require(offset >= 0 && offset.toLong() + 4 <= data.limit())
        return data.getInt(offset).toLong() and 0xffffffffL
    }
    init {
        val signature = u32(0)
        val base = if (signature == 0x74746366L) {
            require(faceIndex >= 0 && faceIndex.toLong() < u32(8))
            u32(12 + faceIndex * 4).also { require(it <= Int.MAX_VALUE) }.toInt()
        } else 0
        require(u32(base) in setOf(0x00010000L, 0x4f54544fL, 0x74727565L))
        val count = u16(base + 4)
        require(base.toLong() + 12 + count * 16L <= data.limit())
        var cmap = -1
        var cmapLength = 0
        for (i in 0 until count) {
            val record = base + 12 + i * 16
            val offset = u32(record + 8)
            val length = u32(record + 12)
            require(offset + length <= data.limit())
            if (u32(record) == 0x636d6170L) { cmap = offset.toInt(); cmapLength = length.toInt() }
            if (u32(record) == 0x6d617870L && length >= 6) glyphCount = u16(offset.toInt() + 4)
        }
        if (cmap >= 0 && cmapLength >= 4) {
            val records = u16(cmap + 2)
            require(4L + records * 8L <= cmapLength)
            for (i in 0 until records) {
                val record = cmap + 4 + i * 8
                val platform = u16(record)
                val encoding = u16(record + 2)
                if (platform != 0 && !(platform == 3 && encoding in setOf(0, 1, 10))) continue
                val relative = u32(record + 4)
                if (relative + 4 > cmapLength) continue
                val start = cmap + relative.toInt()
                val format = u16(start)
                if (format !in setOf(4, 12, 13)) continue
                val length = if (format == 4) u16(start + 2).toLong() else u32(start + 4)
                if (length < (if (format == 4) 16 else 16) || relative + length > cmapLength) continue
                if (format == 4 && 16L + (u16(start + 6) / 2) * 8L > length) continue
                if (format != 4 && 16L + u32(start + 12) * 12L > length) continue
                subtables.add(Subtable(start, length.toInt(), format))
            }
        }
    }
    fun hasGlyph(codePoint: Int): Boolean {
        if (codePoint !in 0..0x10ffff || codePoint in 0xd800..0xdfff) return false
        return subtables.any { table ->
            val glyph = if (table.format == 4) glyph4(table, codePoint) else glyph12(table, codePoint)
            glyph > 0 && glyph < glyphCount
        }
    }
    fun supportsHangul(): Boolean = (0xac00..0xd7a3).all { hasGlyph(it) }

    private fun glyph4(table: Subtable, codePoint: Int): Int {
        if (codePoint > 0xffff) return 0
        val start = table.offset
        val count = u16(start + 6) / 2
        val ends = start + 14
        var low = 0
        var high = count
        while (low < high) {
            val mid = (low + high) ushr 1
            if (u16(ends + mid * 2) < codePoint) low = mid + 1 else high = mid
        }
        if (low == count) return 0
        val starts = ends + count * 2 + 2
        val first = u16(starts + low * 2)
        if (codePoint < first) return 0
        val delta = starts + count * 2
        val ranges = delta + count * 2
        val range = u16(ranges + low * 2)
        if (range == 0) return (codePoint + u16(delta + low * 2)) and 0xffff
        val address = ranges.toLong() + low * 2 + range + (codePoint - first) * 2
        if (address < start || address + 2 > start.toLong() + table.length) return 0
        val glyph = u16(address.toInt())
        return if (glyph == 0) 0 else (glyph + u16(delta + low * 2)) and 0xffff
    }
    private fun glyph12(table: Subtable, codePoint: Int): Int {
        var low = 0
        var high = u32(table.offset + 12).toInt()
        while (low < high) {
            val mid = (low + high) ushr 1
            val group = table.offset + 16 + mid * 12
            val first = u32(group)
            val last = u32(group + 4)
            if (codePoint.toLong() < first) high = mid
            else if (codePoint.toLong() > last) low = mid + 1
            else {
                val glyph = u32(group + 8) + if (table.format == 13) 0 else codePoint.toLong() - first
                return if (glyph <= Int.MAX_VALUE) glyph.toInt() else 0
            }
        }
        return 0
    }
}
