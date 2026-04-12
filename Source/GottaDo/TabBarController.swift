import UIKit

final class TabBarController: UITabBarController {

    private let barBackgroundColor = UIColor(red: 0.3235799670, green: 0.1942589879, blue: 0.3807701170, alpha: 1.0)
    private let selectedColor = UIColor(white: 0.8941, alpha: 1.0)
    private let unselectedColor = UIColor(white: 0.75, alpha: 1.0)
    private let preferredItemWidth: CGFloat = 96
    private let minimumItemSpacing: CGFloat = 56
    private let maximumItemSpacing: CGFloat = 120
    private let preferredCenterGapMultiplier: CGFloat = 1.6
    private let debugButtonSize: CGFloat = 24
    private let debugButtonLeadingInset: CGFloat = 12
    private let debugButtonBottomInset: CGFloat = 12

    private let debugButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabBarAppearance()
        installDebugButton()
        updateTabBarLayoutMetrics()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarLayoutMetrics()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barBackgroundColor
        appearance.shadowColor = .clear

        let itemAppearances = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]

        for itemAppearance in itemAppearances {
            itemAppearance.normal.iconColor = unselectedColor
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: unselectedColor,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            itemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
            itemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = false
        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = unselectedColor
    }

    private func installDebugButton() {
        guard debugButton.superview == nil else { return }

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: imageConfig), for: .normal)
        debugButton.tintColor = selectedColor.withAlphaComponent(0.65)
        debugButton.backgroundColor = .clear
        debugButton.layer.cornerRadius = 0
        debugButton.layer.borderWidth = 0
        debugButton.addTarget(self, action: #selector(showDebugModal), for: .touchUpInside)
        debugButton.accessibilityLabel = "Debug"
        debugButton.accessibilityHint = "Open debug tools"

        tabBar.addSubview(debugButton)

        NSLayoutConstraint.activate([
            debugButton.widthAnchor.constraint(equalToConstant: debugButtonSize),
            debugButton.heightAnchor.constraint(equalToConstant: debugButtonSize),
            debugButton.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: debugButtonLeadingInset),
            debugButton.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor, constant: -debugButtonBottomInset)
        ])
    }

    private func updateTabBarLayoutMetrics() {
        tabBar.itemPositioning = .centered
        tabBar.itemWidth = preferredItemWidth
        tabBar.itemSpacing = preferredItemSpacing(for: tabBar.bounds.width)
    }

    private func preferredItemSpacing(for tabBarWidth: CGFloat) -> CGFloat {
        let itemCount = CGFloat(tabBar.items?.count ?? 0)
        guard itemCount == 2 else { return minimumItemSpacing }

        let availableGapWidth = max(0, tabBarWidth - (preferredItemWidth * itemCount))
        let preferredSpacing = availableGapWidth * preferredCenterGapMultiplier / (2 + preferredCenterGapMultiplier)
        return min(max(preferredSpacing, minimumItemSpacing), maximumItemSpacing)
    }

    @objc
    private func showDebugModal() {
        performSegue(withIdentifier: "debugSegue", sender: nil)
        HapticHelper.generateSmallFeedback()
    }
}
