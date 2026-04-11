import UIKit

class DebugViewController: UIViewController {
    private weak var topNavigationBar: UINavigationBar?
    private var topNavigationBarHeightConstraint: NSLayoutConstraint?
    private var closeButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTopNavigationBarLayout()
    }

    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    private func updateTopNavigationBarLayout() {
        if topNavigationBar == nil {
            topNavigationBar = view.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar
        }

        guard let navigationBar = topNavigationBar else { return }

        if closeButton == nil {
            navigationBar.items?.forEach { $0.leftBarButtonItem = nil }

            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Close", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
            view.addSubview(button)

            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
            ])

            closeButton = button
        }

        let targetHeight = max(56, view.safeAreaInsets.top + 44)
        if topNavigationBarHeightConstraint == nil {
            let heightConstraint = navigationBar.heightAnchor.constraint(equalToConstant: targetHeight)
            heightConstraint.isActive = true
            topNavigationBarHeightConstraint = heightConstraint
        } else {
            topNavigationBarHeightConstraint?.constant = targetHeight
        }
    }
}
