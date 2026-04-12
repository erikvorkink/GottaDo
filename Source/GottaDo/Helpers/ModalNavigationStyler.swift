import UIKit

enum ModalNavigationStyler {
    private static let barColor = UIColor(red: 0.3955705762, green: 0.2770622373, blue: 0.4479630589, alpha: 1.0)
    private static let primaryActionColor = UIColor.white
    private static let secondaryActionColor = UIColor.white.withAlphaComponent(0.72)

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
}
