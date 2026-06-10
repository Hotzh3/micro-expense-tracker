import Foundation

struct ShareExtensionStrings {
    let title: String
    let received: String
    let instruction: String
    let openPocketLeak: String
    let cancel: String
    let noText: String
    let openFailed: String

    static var current: ShareExtensionStrings {
        switch Locale.preferredLanguages.first?.prefix(2).lowercased() {
        case "es":
            return ShareExtensionStrings(
                title: "Enviar a Pocket Leak",
                received: "Texto recibido",
                instruction: "Abre Pocket Leak para revisarlo.",
                openPocketLeak: "Abrir Pocket Leak",
                cancel: "Cancelar",
                noText: "No se pudo leer texto compartido.",
                openFailed: "No se pudo abrir Pocket Leak. Ábrelo manualmente."
            )
        default:
            return ShareExtensionStrings(
                title: "Send to Pocket Leak",
                received: "Text received",
                instruction: "Open Pocket Leak to review.",
                openPocketLeak: "Open Pocket Leak",
                cancel: "Cancel",
                noText: "No shared text could be read.",
                openFailed: "Could not open Pocket Leak. Open it manually."
            )
        }
    }
}
