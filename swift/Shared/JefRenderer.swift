import Foundation
import CoreGraphics
import ImageIO
import os

let jefLog = Logger(subsystem: "com.flowdev.jefpreviwe", category: "render")

enum JefRenderError: LocalizedError {
    case parseFailed(String)
    case renderFailed(String)

    var errorDescription: String? {
        switch self {
        case .parseFailed(let m): return "JEF parse failed: \(m)"
        case .renderFailed(let m): return "JEF render failed: \(m)"
        }
    }
}

enum JefBackground { case transparent, white }

/// Нативный рендер .jef → CGImage. Порт jef_render.py (без Python-подпроцесса —
/// QuickLook-расширения не могут порождать процессы в своей sandbox).
struct JefRenderer {

    static let supersample = 2
    // Запасная палитра, если в файле нет данных о нитях (как в jef_render.py).
    static let fallback: [UInt32] = [
        0x1A76BC, 0xD83A3E, 0x34A048, 0xF0921F, 0x7E57C2, 0x009688,
    ]

    static func renderImage(fileURL: URL, size: Int, background: JefBackground,
                            lineWidthMM: CGFloat = 2.2, drawJumps: Bool = false) throws -> CGImage {
        let data = try Data(contentsOf: fileURL)
        let pattern = try JefParser.parse(data)
        jefLog.log("parsed: stitches=\(pattern.stitches.count, privacy: .public) colors=\(pattern.colors.count, privacy: .public)")
        return try draw(pattern, size: size, background: background,
                        lineWidthMM: lineWidthMM, drawJumps: drawJumps)
    }

    static func renderPNG(fileURL: URL, size: Int, background: JefBackground) throws -> Data {
        let img = try renderImage(fileURL: fileURL, size: size, background: background)
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            out as CFMutableData, "public.png" as CFString, 1, nil
        ) else { throw JefRenderError.renderFailed("не удалось создать PNG-назначение") }
        CGImageDestinationAddImage(dest, img, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw JefRenderError.renderFailed("не удалось сериализовать PNG")
        }
        return out as Data
    }

    @inline(__always) private static func rgb(_ hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
        (CGFloat((hex >> 16) & 0xFF) / 255.0,
         CGFloat((hex >> 8) & 0xFF) / 255.0,
         CGFloat(hex & 0xFF) / 255.0)
    }

    private static func draw(_ pat: JefPattern, size: Int, background: JefBackground,
                             lineWidthMM: CGFloat, drawJumps: Bool) throws -> CGImage {
        let canvas = size * supersample
        let cd = Double(canvas)
        let w = max(pat.maxX - pat.minX, 1)
        let h = max(pat.maxY - pat.minY, 1)
        let pad = 0.05 * cd
        let scale = min((cd - 2 * pad) / w, (cd - 2 * pad) / h)
        let ox = (cd - w * scale) / 2 - pat.minX * scale
        let oy = (cd - h * scale) / 2 - pat.minY * scale
        @inline(__always) func px(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: x * scale + ox, y: y * scale + oy)
        }

        let cs = CGColorSpaceCreateDeviceRGB()
        let bmp = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: nil, width: canvas, height: canvas,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: cs, bitmapInfo: bmp) else {
            throw JefRenderError.renderFailed("не удалось создать графический контекст")
        }

        if case .white = background {
            ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
        }

        // Ориентация как в PIL (origin сверху-слева): переворачиваем ось Y.
        ctx.translateBy(x: 0, y: cd)
        ctx.scaleBy(x: 1, y: -1)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        let lw = max(1.0, (lineWidthMM * CGFloat(supersample) * CGFloat(size) / 1024.0).rounded())
        ctx.setLineWidth(lw)

        let colors = pat.colors
        func colorFor(_ i: Int) -> (CGFloat, CGFloat, CGFloat) {
            if !colors.isEmpty { return rgb(colors[i % colors.count]) }
            return rgb(fallback[i % fallback.count])
        }

        var idx = 0
        var seg: [CGPoint] = []
        func flush() {
            if seg.count >= 2 {
                let c = colorFor(idx)
                ctx.setStrokeColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
                ctx.beginPath()
                ctx.addLines(between: seg)
                ctx.strokePath()
            }
            seg.removeAll(keepingCapacity: true)
        }

        for s in pat.stitches {
            switch s.cmd {
            case .stitch:
                seg.append(px(s.x, s.y))
            case .jump:
                if drawJumps && !seg.isEmpty { seg.append(px(s.x, s.y)) }
                flush()
                seg = [px(s.x, s.y)]
            case .colorChange:
                flush(); idx += 1
            case .stop:
                flush()
            case .end:
                flush()
            }
        }
        flush()

        guard let full = ctx.makeImage() else {
            throw JefRenderError.renderFailed("makeImage вернул nil")
        }
        // Даунсэмплинг supersample→size с качественной интерполяцией (антиалиасинг).
        guard let down = CGContext(data: nil, width: size, height: size,
                                   bitsPerComponent: 8, bytesPerRow: 0,
                                   space: cs, bitmapInfo: bmp) else {
            return full
        }
        down.interpolationQuality = .high
        down.draw(full, in: CGRect(x: 0, y: 0, width: size, height: size))
        return down.makeImage() ?? full
    }
}
