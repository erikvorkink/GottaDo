import UIKit

enum ModalNavigationStyler {
    private static let barColor = UIColor(red: 0.3955705762, green: 0.2770622373, blue: 0.4479630589, alpha: 1.0)
    private static let primaryActionColor = UIColor.white
    private static let secondaryActionColor = barColor
    private static let secondaryActionBackgroundColor = UIColor.white

    static func apply(to navigationController: UINavigationController?) {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = primaryActionColor
        navigationBar.prefersLargeTitles = false
    }

    static func applySecondaryActionStyle(to barButtonItem: UIBarButtonItem?) {
        barButtonItem?.tintColor = secondaryActionColor
    }

    static func makeSecondaryActionButton(title: String, target: Any?, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(secondaryActionColor, for: .normal)
        button.setTitleColor(secondaryActionColor.withAlphaComponent(0.75), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = secondaryActionBackgroundColor
        button.layer.cornerRadius = 15
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.sizeToFit()
        return UIBarButtonItem(customView: button)
    }
}
