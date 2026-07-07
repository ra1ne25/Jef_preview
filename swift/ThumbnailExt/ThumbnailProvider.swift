import QuickLookThumbnailing
import AppKit

/// Миниатюры .jef в Finder (иконки файлов). Рендер нативный (Core Graphics).
class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        do {
            let maxSize = request.maximumSize
            let side = max(Int(min(maxSize.width, maxSize.height) * request.scale), 64)
            let img = try JefRenderer.renderImage(
                fileURL: request.fileURL,
                size: side,
                background: .transparent
            )
            let reply = QLThumbnailReply(contextSize: maxSize) { () -> Bool in
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                ctx.draw(img, in: CGRect(origin: .zero, size: maxSize))
                return true
            }
            handler(reply, nil)
        } catch {
            jefLog.error("provideThumbnail error: \(String(describing: error), privacy: .public)")
            handler(nil, error)
        }
    }
}
