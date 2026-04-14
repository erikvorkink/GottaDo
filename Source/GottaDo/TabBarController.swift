import UIKit

final class TabBarController: UITabBarController {

    private let barBackgroundColor = UIColor(red: 0.3235799670, green: 0.1942589879, blue: 0.3807701170, alpha: 1.0)
    private let selectedColor = UIColor(white: 0.97, alpha: 1.0)
    private let unselectedColor = UIColor(white: 0.86, alpha: 1.0)
    private let preferredItemWidth: CGFloat = 84
    private let minimumItemSpacing: CGFloat = 72
    private let maximumItemSpacing: CGFloat = 148
    private let preferredCenterGapMultiplier: CGFloat = 2.35
    private let maintenanceHotspotWidth: CGFloat = 44
    private let maintenanceLongPressDuration: TimeInterval = 0.4
    private let navigationHitTargetVerticalInset: CGFloat = 6
    private let maintenanceHotspotView = UIView()
    private let todayHitTargetView = UIControl()
    private let backlogHitTargetView = UIControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabBarAppearance()
        installMaintenanceHotspot()
        installExpandedTabHitTargets()
        updateTabBarLayoutMetrics()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarLayoutMetrics()
        view.bringSubviewToFront(todayHitTargetView)
        view.bringSubviewToFront(backlogHitTargetView)
        view.bringSubviewToFront(maintenanceHotspotView)
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

    private func installMaintenanceHotspot() {
        guard maintenanceHotspotView.superview == nil else { return }

        maintenanceHotspotView.translatesAutoresizingMaskIntoConstraints = false
        maintenanceHotspotView.backgroundColor = .clear
        maintenanceHotspotView.isUserInteractionEnabled = true
        view.addSubview(maintenanceHotspotView)

        NSLayoutConstraint.activate([
            maintenanceHotspotView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            maintenanceHotspotView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            maintenanceHotspotView.widthAnchor.constraint(equalToConstant: maintenanceHotspotWidth),
            maintenanceHotspotView.heightAnchor.constraint(equalTo: tabBar.heightAnchor)
        ])

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMaintenanceLongPress(_:)))
        longPressRecognizer.minimumPressDuration = maintenanceLongPressDuration
        maintenanceHotspotView.addGestureRecognizer(longPressRecognizer)
    }

    private func installExpandedTabHitTargets() {
        guard todayHitTargetView.superview == nil, backlogHitTargetView.superview == nil else { return }

        todayHitTargetView.translatesAutoresizingMaskIntoConstraints = false
        backlogHitTargetView.translatesAutoresizingMaskIntoConstraints = false

        todayHitTargetView.backgroundColor = .clear
        backlogHitTargetView.backgroundColor = .clear

        todayHitTargetView.addTarget(self, action: #selector(selectTodayTab), for: .touchUpInside)
        backlogHitTargetView.addTarget(self, action: #selector(selectBacklogTab), for: .touchUpInside)

        view.addSubview(todayHitTargetView)
        view.addSubview(backlogHitTargetView)

        NSLayoutConstraint.activate([
            todayHitTargetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            todayHitTargetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            todayHitTargetView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: navigationHitTargetVerticalInset),
            todayHitTargetView.trailingAnchor.constraint(equalTo: view.centerXAnchor),

            backlogHitTargetView.leadingAnchor.constraint(equalTo: view.centerXAnchor),
            backlogHitTargetView.trailingAnchor.constraint(equalTo: maintenanceHotspotView.leadingAnchor),
            backlogHitTargetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backlogHitTargetView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: navigationHitTargetVerticalInset)
        ])
    }

    @objc
    private func handleMaintenanceLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        showMaintenanceModal()
    }

    @objc
    private func selectTodayTab() {
        selectedIndex = 0
    }

    @objc
    private func selectBacklogTab() {
        guard (tabBar.items?.count ?? 0) > 1 else { return }
        selectedIndex = 1
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
