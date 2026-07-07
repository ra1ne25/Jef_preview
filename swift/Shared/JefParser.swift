import Foundation

/// Один стежок в абсолютных координатах (единицы JEF = 0.1 мм).
struct JefStitch {
    enum Command { case stitch, jump, colorChange, stop, end }
    let x: Double
    let y: Double
    let cmd: Command
}

/// Разобранный паттерн вышивки.
struct JefPattern {
    var colors: [UInt32]      // реальные цвета нитей по порядку (None-слоты исключены)
    var stitches: [JefStitch] // абсолютные координаты
    var minX: Double, minY: Double, maxX: Double, maxY: Double

    var widthMM: Double { (maxX - minX) / 10.0 }
    var heightMM: Double { (maxY - minY) / 10.0 }
}

/// Нативный парсер .jef (Janome). Порт pyembroidery JefReader.read / read_jef_stitches.
enum JefParser {

    /// Палитра Janome (pyembroidery EmbThreadJef.get_thread_set).
    /// Индекс 0 — плейсхолдер (None в оригинале), реальные нити 1..78. len = 79.
    static let palette: [UInt32] = [
        0x000000, 0x000000, 0xFFFFFF, 0xFFFF17, 0xFF6600, 0x2F5933, 0x237336, 0x65C2C8,
        0xAB5A96, 0xF669A0, 0xFF0000, 0xB1704E, 0x0B2F84, 0xE4C35D, 0x481A05, 0xAC9CC7,
        0xFCF294, 0xF999B7, 0xFAB381, 0xC9A480, 0x970533, 0xA0B8CC, 0x7FC21C, 0xE5E5E5,
        0x889B9B, 0x98D6BD, 0xB2E1E3, 0x368BA0, 0x4F83AB, 0x386A91, 0x071650, 0xF999A2,
        0xF9676B, 0xE3311F, 0xE2A188, 0xB59474, 0xE4CF99, 0xFFCB00, 0xE1ADD4, 0xC3007E,
        0x80004B, 0x540571, 0xB10525, 0xCAE0C0, 0x899856, 0x5C941A, 0x003114, 0x5DAE94,
        0x4CBF8F, 0x007772, 0x595B61, 0xFFFFF2, 0xB15818, 0xCB8A07, 0x986C80, 0x98692D,
        0x4D3419, 0x4C330B, 0x33200A, 0x523A97, 0x0D217E, 0x1E77AC, 0xB2DD53, 0xF33689,
        0xDE649E, 0x984161, 0x4C5612, 0x4C881F, 0xE4DE79, 0xCB8A1A, 0xCBA21C, 0xFF9805,
        0xFCB257, 0xFFE505, 0xF0331F, 0x1A842D, 0x386CAE, 0xE3C4B4, 0xE3AC81,
    ]

    @inline(__always) static func signed8(_ b: UInt8) -> Int {
        return b < 128 ? Int(b) : Int(b) - 256
    }

    @inline(__always) static func int32le(_ d: Data, _ off: Int) -> Int {
        let base = d.startIndex + off
        let v = UInt32(d[base]) | (UInt32(d[base + 1]) << 8)
              | (UInt32(d[base + 2]) << 16) | (UInt32(d[base + 3]) << 24)
        return Int(Int32(bitPattern: v))
    }

    static func parse(_ data: Data) throws -> JefPattern {
        guard data.count >= 116 else {
            throw JefRenderError.parseFailed("файл слишком мал (\(data.count) байт)")
        }
        let stitchOffset = int32le(data, 0)
        let countColors = int32le(data, 24)
        guard countColors >= 0, countColors < 10000 else {
            throw JefRenderError.parseFailed("некорректное число цветов: \(countColors)")
        }

        // Таблица цветов начинается со смещения 116.
        var slots: [UInt32?] = []
        var p = 116
        for _ in 0..<countColors {
            guard p + 4 <= data.count else { break }
            let index = abs(int32le(data, p)); p += 4
            if index == 0 { slots.append(nil) }
            else { slots.append(palette[index % palette.count]) }
        }
        let realColors = slots.compactMap { $0 }

        // Стежки.
        guard stitchOffset >= 0, stitchOffset <= data.count else {
            throw JefRenderError.parseFailed("некорректное смещение стежков: \(stitchOffset)")
        }
        var stitches: [JefStitch] = []
        var x = 0.0, y = 0.0
        var minX = Double.greatestFiniteMagnitude, minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude, maxY = -Double.greatestFiniteMagnitude
        @inline(__always) func bound() {
            if x < minX { minX = x }; if y < minY { minY = y }
            if x > maxX { maxX = x }; if y > maxY { maxY = y }
        }

        var pos = stitchOffset
        var slotIdx = 1  // как color_index в pyembroidery
        loop: while pos + 2 <= data.count {
            let b0 = data[data.startIndex + pos], b1 = data[data.startIndex + pos + 1]
            pos += 2
            if b0 != 0x80 {
                x += Double(signed8(b0)); y += Double(-signed8(b1))
                bound()
                stitches.append(JefStitch(x: x, y: y, cmd: .stitch))
                continue
            }
            let ctrl = b1
            guard pos + 2 <= data.count else { break }
            let b2 = data[data.startIndex + pos], b3 = data[data.startIndex + pos + 1]
            pos += 2
            let dx = Double(signed8(b2)), dy = Double(-signed8(b3))
            switch ctrl {
            case 0x02:  // jump / move
                x += dx; y += dy; bound()
                stitches.append(JefStitch(x: x, y: y, cmd: .jump))
            case 0x01:  // color change (или stop, если слот None — цвет #0)
                let isNone = (slotIdx < slots.count) ? (slots[slotIdx] == nil) : false
                stitches.append(JefStitch(x: x, y: y, cmd: isNone ? .stop : .colorChange))
                slotIdx += 1
            case 0x10:  // end
                break loop
            default:
                break loop
            }
        }
        stitches.append(JefStitch(x: x, y: y, cmd: .end))

        if minX > maxX { minX = 0; minY = 0; maxX = 1; maxY = 1 }
        guard stitches.count > 1 else {
            throw JefRenderError.parseFailed("нет стежков")
        }
        return JefPattern(colors: realColors, stitches: stitches,
                          minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }
}
