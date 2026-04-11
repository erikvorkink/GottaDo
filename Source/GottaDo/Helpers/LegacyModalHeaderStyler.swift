import UIKit

struct LegacyModalHeaderButtonConfiguration {
    enum Content {
        case title(String)
        case systemImage(String)
    }

    let content: Content
    let action: Selector
    let accessibilityLabel: String?
}

final class LegacyModalHeaderStyler {
    private weak var viewController: UIViewController?
    private weak var navigationBar: UINavigationBar?
    private var navigationBarHeightConstraint: NSLayoutConstraint?
    private var installedButtons: [UIButton] = []

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func update(left: LegacyModalHeaderButtonConfiguration?, right: LegacyModalHeaderButtonConfiguration?) {
        guard let viewController else { return }

        if navigationBar == nil {
            navigationBar = viewController.view.firstSubview(ofType: UINavigationBar.self)
        }

        guard let navigationBar else { return }

        installButtonsIfNeeded(on: viewController.view, navigationBar: navigationBar, left: left, right: right)

        let targetHeight = max(56, viewController.view.safeAreaInsets.top + 44)
        if navigationBarHeightConstraint == nil {
            navigationBarHeightConstraint = navigationBar.heightAnchor.constraint(equalToConstant: targetHeight)
            navigationBarHeightConstraint?.isActive = true
        } else {
            navigationBarHeightConstraint?.constant = targetHeight
        }
    }

    private func installButtonsIfNeeded(
        on view: UIView,
        navigationBar: UINavigationBar,
        left: LegacyModalHeaderButtonConfiguration?,
        right: LegacyModalHeaderButtonConfiguration?
    ) {
        guard installedButtons.isEmpty else { return }

        navigationBar.items?.forEach {
            $0.leftBarButtonItem = nil
            $0.rightBarButtonItem = nil
        }

        if let left {
            installedButtons.append(makeButton(from: left, in: view, anchor: .left))
        }

        if let right {
            installedButtons.append(makeButton(from: right, in: view, anchor: .right))
        }
    }

    private func makeButton(
        from configuration: LegacyModalHeaderButtonConfiguration,
        in view: UIView,
        anchor: HorizontalAnchor
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)

        switch configuration.content {
        case let .title(title):
            button.setTitle(title, for: .normal)
        case let .systemImage(name):
            let image = UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.accessibilityLabel = configuration.accessibilityLabel ?? name
        }

        if let accessibilityLabel = configuration.accessibilityLabel {
            button.accessibilityLabel = accessibilityLabel
        }

        button.addTarget(viewController, action: configuration.action, for: .touchUpInside)
        view.addSubview(button)

        let topConstraint = button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        let horizontalConstraint: NSLayoutConstraint

        switch anchor {
        case .left:
            horizontalConstraint = button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        case .right:
            horizontalConstraint = button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        }

        NSLayoutConstraint.activate([topConstraint, horizontalConstraint])
        return button
    }
}

private enum HorizontalAnchor {
    case left
    case right
}

private extension UIView {
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        if let match = self as? T {
            return match
        }

        for subview in subviews {
            if let match = subview.firstSubview(ofType: type) {
                return match
            }
        }

        return nil
    }
}
