import SwiftUI

@main
struct JTapApp: App {
    @StateObject private var viewModel = ExpenseViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
