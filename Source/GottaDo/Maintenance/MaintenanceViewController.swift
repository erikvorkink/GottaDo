import UIKit

class MaintenanceViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }

    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    private func configureNavigation() {
        ModalNavigationStyler.apply(to: navigationController)
        title = "Maintenance"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close(_:))
        )
    }
}
