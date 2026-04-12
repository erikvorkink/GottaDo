import UIKit

class TaskEditViewController: TaskEditorViewController {

    var task: Task?
    var appContext: AppContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        initEditor()
    }

    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func close(_ sender: Any) {
        saveNameAndClose()
    }

    @objc
    func saveNameAndClose() {
        if saveName() {
            NotificationCenter.default.post(name: .taskEdited, object: nil)
            HapticHelper.generateBigFeedback()
            closeKeyboard()
            close()
        }
    }

    @IBAction func remove(_ sender: Any) {
        if remove() {
            NotificationCenter.default.post(name: .taskDeleted, object: nil)
            HapticHelper.generateBigFeedback()
            closeKeyboard()
            close()
        }
    }

    func closeKeyboard() {
        nameField.resignFirstResponder()
    }

    func initEditor() {
        guard let task else { return }

        nameField.text = task.name
        nameField.addTarget(self, action: #selector(saveNameAndClose), for: .editingDidEndOnExit)
    }

    private func configureNavigation() {
        ModalNavigationStyler.apply(to: navigationController)
        navigationItem.title = ""
        navigationItem.leftBarButtonItem = ModalNavigationStyler.makeSecondaryActionButton(
            title: "Close",
            target: self,
            action: #selector(close(_:))
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(remove(_:))
        )
    }

    func saveName() -> Bool {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return false }
        guard let task else { return false }

        if !nameField.isValidText() {
            alert("Invalid task name")
            return false
        }

        task.setName(nameField.getTrimmedText())
        do {
            try appContext.saveContext()
        } catch {
            alert("Unable to rename task")
            return false
        }
        return true
    }

    func remove() -> Bool {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return false }
        guard let task else { return false }

        task.remove()
        do {
            try appContext.saveContext()
        } catch {
            alert("Unable to remove task")
            return false
        }
        return true
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }
}
