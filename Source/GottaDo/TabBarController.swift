import UIKit

final class TabBarController: UITabBarController {

    private let barBackgroundColor = UIColor(red: 0.3235799670, green: 0.1942589879, blue: 0.3807701170, alpha: 1.0)
    private let selectedColor = UIColor(white: 0.8941, alpha: 1.0)
    private let unselectedColor = UIColor(white: 0.75, alpha: 1.0)
    private let preferredItemWidth: CGFloat = 96
    private let minimumItemSpacing: CGFloat = 56
    private let maximumItemSpacing: CGFloat = 120
    private let preferredCenterGapMultiplier: CGFloat = 1.6
    private let maintenanceButtonSize: CGFloat = 24
    private let maintenanceButtonLeadingInset: CGFloat = 12
    private let maintenanceButtonBottomInset: CGFloat = 12

    private let maintenanceButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabBarAppearance()
        installMaintenanceButton()
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

    private func installMaintenanceButton() {
        guard maintenanceButton.superview == nil else { return }

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        maintenanceButton.translatesAutoresizingMaskIntoConstraints = false
        maintenanceButton.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: imageConfig), for: .normal)
        maintenanceButton.tintColor = selectedColor.withAlphaComponent(0.65)
        maintenanceButton.backgroundColor = .clear
        maintenanceButton.layer.cornerRadius = 0
        maintenanceButton.layer.borderWidth = 0
        maintenanceButton.addTarget(self, action: #selector(showMaintenanceModal), for: .touchUpInside)
        maintenanceButton.accessibilityLabel = "Maintenance"
        maintenanceButton.accessibilityHint = "Open maintenance tools"

        tabBar.addSubview(maintenanceButton)

        NSLayoutConstraint.activate([
            maintenanceButton.widthAnchor.constraint(equalToConstant: maintenanceButtonSize),
            maintenanceButton.heightAnchor.constraint(equalToConstant: maintenanceButtonSize),
            maintenanceButton.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: maintenanceButtonLeadingInset),
            maintenanceButton.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor, constant: -maintenanceButtonBottomInset)
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
    private func showMaintenanceModal() {
        performSegue(withIdentifier: "maintenanceSegue", sender: nil)
        HapticHelper.generateSmallFeedback()
    }
}
