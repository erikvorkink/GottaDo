import UIKit

final class TabBarController: UITabBarController {

    private let longPressRightEdgeThreshold: CGFloat = 40
    private let barBackgroundColor = UIColor(red: 0.3235799670, green: 0.1942589879, blue: 0.3807701170, alpha: 1.0)
    private let selectedColor = UIColor(white: 0.8941, alpha: 1.0)
    private let unselectedColor = UIColor(white: 0.75, alpha: 1.0)

    private let customBarView = UIView()
    private var customButtons: [UIControl] = []
    private var customButtonCenterConstraints: [NSLayoutConstraint] = []
    private var customBarHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSystemTabBar()
        installCustomBar()
        updateCustomSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCustomBar()
    }

    override var selectedIndex: Int {
        didSet {
            updateCustomSelection()
        }
    }

    private func configureSystemTabBar() {
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
            itemAppearance.normal.iconColor = .clear
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            itemAppearance.selected.iconColor = .clear
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = false
        tabBar.tintColor = .clear
        tabBar.unselectedItemTintColor = .clear
        tabBar.selectionIndicatorImage = UIImage()
        tabBar.itemWidth = 0
        tabBar.itemSpacing = 0
        tabBar.itemPositioning = .automatic
    }

    private func installCustomBar() {
        guard customBarView.superview == nil else { return }

        customBarView.translatesAutoresizingMaskIntoConstraints = false
        customBarView.backgroundColor = barBackgroundColor
        customBarView.isUserInteractionEnabled = true
        view.addSubview(customBarView)

        customBarHeightConstraint = customBarView.heightAnchor.constraint(equalToConstant: tabBar.frame.height)

        NSLayoutConstraint.activate([
            customBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customBarHeightConstraint!
        ])

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        customBarView.addGestureRecognizer(longPressRecognizer)

        customButtons = (tabBar.items ?? []).enumerated().map { index, item in
            let control = makeTabControl(title: item.title ?? "", image: item.image, index: index)
            customBarView.addSubview(control)
            return control
        }
    }

    private func layoutCustomBar() {
        guard customBarView.superview != nil else { return }

        customBarHeightConstraint?.constant = tabBar.frame.height
        view.bringSubviewToFront(customBarView)

        layoutCustomButtons()
    }

    private func layoutCustomButtons() {
        guard customButtons.count == 2 else { return }

        NSLayoutConstraint.deactivate(customButtonCenterConstraints)
        customButtonCenterConstraints.removeAll()

        let leftButton = customButtons[0]
        let rightButton = customButtons[1]
        let verticalOffset: CGFloat = -10

        customButtonCenterConstraints = [
            leftButton.centerXAnchor.constraint(equalTo: customBarView.leadingAnchor, constant: customBarView.bounds.width * 0.25),
            rightButton.centerXAnchor.constraint(equalTo: customBarView.leadingAnchor, constant: customBarView.bounds.width * 0.75),
            leftButton.centerYAnchor.constraint(equalTo: customBarView.centerYAnchor, constant: verticalOffset),
            rightButton.centerYAnchor.constraint(equalTo: customBarView.centerYAnchor, constant: verticalOffset)
        ]
        NSLayoutConstraint.activate(customButtonCenterConstraints)
    }

    private func makeTabControl(title: String, image: UIImage?, index: Int) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.tag = index
        control.addTarget(self, action: #selector(handleCustomTabTap(_:)), for: .touchUpInside)

        let imageView = UIImageView(image: image?.withRenderingMode(.alwaysTemplate))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = unselectedColor
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = unselectedColor
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isUserInteractionEnabled = false

        control.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            stack.topAnchor.constraint(equalTo: control.topAnchor),
            stack.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            control.widthAnchor.constraint(equalToConstant: 96)
        ])

        control.accessibilityLabel = title
        control.accessibilityTraits = .button
        control.layer.cornerRadius = 0
        control.layer.masksToBounds = false

        return control
    }

    @objc
    private func handleCustomTabTap(_ sender: UIControl) {
        selectedIndex = sender.tag
    }

    private func updateCustomSelection() {
        for (index, control) in customButtons.enumerated() {
            let isSelected = index == selectedIndex
            let color = isSelected ? selectedColor : unselectedColor

            if let stack = control.subviews.first as? UIStackView {
                for arrangedSubview in stack.arrangedSubviews {
                    if let imageView = arrangedSubview as? UIImageView {
                        imageView.tintColor = color
                    } else if let label = arrangedSubview as? UILabel {
                        label.textColor = color
                    }
                }
            }
        }
    }

    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            let touchPoint = recognizer.location(in: view)
            if touchedCloseToRightEdge(touchPoint) {
                performSegue(withIdentifier: "debugSegue", sender: nil)
                HapticHelper.generateSmallFeedback()
            }
        }
    }

    private func touchedCloseToRightEdge(_ touchPoint: CGPoint) -> Bool {
        return view.bounds.maxX - touchPoint.x <= longPressRightEdgeThreshold
    }
}
