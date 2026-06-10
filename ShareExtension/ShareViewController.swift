import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let strings = ShareExtensionStrings.current
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let textView = UITextView()
    private let primaryButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private var sharedText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        loadSharedText()
    }

    private func configureLayout() {
        titleLabel.text = strings.title
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        statusLabel.text = strings.instruction
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 14
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.text = strings.noText
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        primaryButton.setTitle(strings.openPocketLeak, for: .normal)
        primaryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        primaryButton.backgroundColor = .label
        primaryButton.setTitleColor(.systemBackground, for: .normal)
        primaryButton.layer.cornerRadius = 16
        primaryButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        primaryButton.addTarget(self, action: #selector(openPocketLeak), for: .touchUpInside)

        cancelButton.setTitle(strings.cancel, for: .normal)
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        cancelButton.backgroundColor = .secondarySystemBackground
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 16
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            statusLabel,
            textView,
            primaryButton,
            cancelButton
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    private func loadSharedText() {
        Task {
            let text = await extractSharedText()
            await MainActor.run {
                applySharedText(text)
            }
        }
    }

    private func applySharedText(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        sharedText = trimmed

        if trimmed.isEmpty {
            statusLabel.text = strings.noText
            textView.text = strings.noText
            primaryButton.isEnabled = false
            primaryButton.alpha = 0.5
            return
        }

        statusLabel.text = strings.received
        textView.text = trimmed
        primaryButton.isEnabled = true
        primaryButton.alpha = 1.0
    }

    @objc private func openPocketLeak() {
        let trimmed = sharedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusLabel.text = strings.noText
            return
        }

        SharedTextStore.shared.savePendingText(trimmed)

        var components = URLComponents()
        components.scheme = "pocketleak"
        components.host = "parse"
        components.queryItems = [URLQueryItem(name: "text", value: trimmed)]

        guard let url = components.url else {
            statusLabel.text = strings.openFailed
            return
        }

        extensionContext?.open(url, completionHandler: { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.finish()
                } else {
                    self.statusLabel.text = self.strings.openFailed
                }
            }
        })
    }

    @objc private func cancelTapped() {
        finish()
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func extractSharedText() async -> String? {
        for case let item as NSExtensionItem in extensionContext?.inputItems ?? [] {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let text = await loadPlainText(from: provider) {
                    return text
                }
            }
        }
        return nil
    }

    private func loadPlainText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSString.self) { object, _ in
                continuation.resume(returning: object as? String)
            }
        }
    }
}
