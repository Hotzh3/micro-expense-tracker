import SwiftUI

enum AppMotion {
    static let quick = Animation.easeOut(duration: 0.18)
    static let standard = Animation.easeOut(duration: 0.24)
    static let emphasis = Animation.easeInOut(duration: 0.3)
    static let toast = Animation.spring(response: 0.28, dampingFraction: 0.92, blendDuration: 0.08)

    static func animation(reduceMotion: Bool, fallback: Animation) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : fallback
    }

    static func transition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }
}
