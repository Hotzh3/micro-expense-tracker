import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let versionText: String
    let onOpenHistory: (() -> Void)?
    let onResetLocalData: () -> Void

    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard

                    privacyCard

                    exportCard

                    settingsCard

                    resetCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .confirmationDialog(
                "Reset local data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Expenses", role: .destructive) {
                    onResetLocalData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes the local expense store on this device. It cannot be undone.")
            }
        }
    }

    private var headerCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pocket Leak")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Minimal iPhone micro-expense capture with local storage, quick parsing, and shareable exports.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(versionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var privacyCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Pocket Leak stores expenses locally and only parses text you paste manually.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var exportCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Export Data")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Open History to share CSV, JSON, or the monthly summary report.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    dismiss()
                    onOpenHistory?()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Open History Exports")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var settingsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("App")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Built for fast, local-first capture.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Text("v0.1")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var resetCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reset")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Delete all locally stored expenses from this device.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset Local Data")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
