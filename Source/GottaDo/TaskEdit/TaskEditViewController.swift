import UIKit

class TaskEditViewController: UIViewController {

    var task: Task?
    private weak var topNavigationBar: UINavigationBar?
    private var topNavigationBarHeightConstraint: NSLayoutConstraint?
    private var closeButton: UIButton?
    private var removeButton: UIButton?
    @IBOutlet weak var nameField: TaskNameField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initEditor()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTopNavigationBarLayout()
    }
    
    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func close(_ sender: Any) {
        self.saveNameAndClose()
    }
    
    @objc
    func saveNameAndClose() {
        if self.saveName() {
            NotificationCenter.default.post(name: NSNotification.Name("taskEditedByModal"), object: nil)
            HapticHelper.generateBigFeedback()
            self.closeKeyboard()
            self.close()
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        if self.remove() {
            NotificationCenter.default.post(name: NSNotification.Name("taskDeletedByModal"), object: nil)
            HapticHelper.generateBigFeedback()
            self.closeKeyboard()
            self.close()
        }
    }
    
    func closeKeyboard() {
        self.nameField.resignFirstResponder() // closes faster than it might by exiting the view
    }
    
    func initEditor() {
        guard let task = task as Task? else { return }

        nameField.text = task.name
        nameField.becomeFirstResponder()
        nameField.addTarget(self, action: #selector(saveNameAndClose), for: .editingDidEndOnExit)
    }

    private func updateTopNavigationBarLayout() {
        if topNavigationBar == nil {
            topNavigationBar = view.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar
        }

        guard let navigationBar = topNavigationBar else { return }

        if closeButton == nil || removeButton == nil {
            navigationBar.items?.forEach {
                $0.leftBarButtonItem = nil
                $0.rightBarButtonItem = nil
            }

            let close = UIButton(type: .system)
            close.translatesAutoresizingMaskIntoConstraints = false
            close.setTitle("Close", for: .normal)
            close.setTitleColor(.white, for: .normal)
            close.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            close.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
            view.addSubview(close)

            let remove = UIButton(type: .system)
            remove.translatesAutoresizingMaskIntoConstraints = false
            let image = UIImage(systemName: "trash")?.withRenderingMode(.alwaysTemplate)
            remove.setImage(image, for: .normal)
            remove.tintColor = .white
            remove.addTarget(self, action: #selector(remove(_:)), for: .touchUpInside)
            view.addSubview(remove)

            NSLayoutConstraint.activate([
                close.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                remove.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                remove.centerYAnchor.constraint(equalTo: close.centerYAnchor)
            ])

            closeButton = close
            removeButton = remove
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
    
    func saveName() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        guard let task = task as Task? else { return false }
        
        if !nameField.isValidText() {
            self.alert("Invalid task name")
            return false
        }
        
        task.setName(nameField.getTrimmedText())
        do {
            try appDelegate.saveContext()
        } catch {
            self.alert("Unable to rename task")
            return false
        }
        return true
    }

    func remove() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        guard let task = task as Task? else { return false }
        
        task.remove()
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to remove task")
            return false
        }
        return true
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
