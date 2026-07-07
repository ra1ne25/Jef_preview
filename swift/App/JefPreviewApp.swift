import SwiftUI

/// Host-приложение. Само по себе ничего не делает — оно контейнер для
/// QuickLook-расширений. Его установка в /Applications регистрирует
/// расширения в LaunchServices; macOS запускает их по требованию.
@main
struct JefPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 44))
                Text("JEF QuickLook").font(.title2).bold()
                Text("Расширения предпросмотра .jef зарегистрированы.\nМиниатюры и предпросмотр (пробел) работают в Finder.\nЭто окно можно закрыть.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(40)
            .frame(width: 420)
        }
    }
}
