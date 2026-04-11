import UIKit

class DebugViewController: UIViewController {
    private lazy var headerStyler = LegacyModalHeaderStyler(viewController: self)

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
        headerStyler.update(
            left: LegacyModalHeaderButtonConfiguration(
                content: .title("Close"),
                action: #selector(close(_:)),
                accessibilityLabel: "Close"
            ),
            right: nil
        )
    }
}
