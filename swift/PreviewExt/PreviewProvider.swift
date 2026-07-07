import QuickLookUI

/// Полноразмерный предпросмотр .jef (пробел в Finder). Data-based API, macOS 12+.
/// Рендер нативный (Core Graphics), без подпроцессов.
class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        jefLog.log("providePreview: \(request.fileURL.lastPathComponent, privacy: .public)")
        let png: Data
        do {
            png = try JefRenderer.renderPNG(fileURL: request.fileURL, size: 1600, background: .white)
        } catch {
            jefLog.error("providePreview error: \(String(describing: error), privacy: .public)")
            throw error
        }
        jefLog.log("providePreview OK: \(png.count) bytes")

        let reply = QLPreviewReply(
            dataOfContentType: .png,
            contentSize: CGSize(width: 800, height: 800)
        ) { _ in png }
        reply.title = request.fileURL.lastPathComponent
        return reply
    }
}
