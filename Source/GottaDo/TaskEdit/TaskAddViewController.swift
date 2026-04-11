import UIKit
import CoreData

class TaskAddViewController: UIViewController {
    
    var newTaskTaskListId: TaskListIds?
    private weak var topNavigationBar: UINavigationBar?
    private var topNavigationBarHeightConstraint: NSLayoutConstraint?
    private var cancelButton: UIButton?
    
    @IBOutlet weak var nameField: TaskNameField!
    @IBOutlet weak var todayButton: UIButton!
    @IBOutlet weak var backlogButton: UIButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
        setStatesOfTaskListChoiceButtons()
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
    
    @IBAction func cancel(_ sender: Any) {
        closeKeyboard()
        close()
    }
    
    @IBAction func chooseToday(_ sender: Any) {
        self.newTaskTaskListId = TaskListIds.Today
        setStatesOfTaskListChoiceButtons()
    }
    
    @IBAction func chooseBacklog(_ sender: Any) {
        self.newTaskTaskListId = TaskListIds.Backlog
        setStatesOfTaskListChoiceButtons()
    }
    
    @objc
    func createTaskAndClose() {
        if createTask() {
            NotificationCenter.default.post(name: NSNotification.Name("taskCreatedByModal"), object: nil)
            HapticHelper.generateBigFeedback()
            close()
        }
    }
    
    func closeKeyboard() {
        self.nameField.resignFirstResponder() // closes faster than it might by exiting the view
    }

    func initEditor() {
        nameField.becomeFirstResponder()
        nameField.addTarget(self, action: #selector(createTaskAndClose), for: .editingDidEndOnExit)
    }

    private func updateTopNavigationBarLayout() {
        if topNavigationBar == nil {
            topNavigationBar = view.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar
        }

        guard let navigationBar = topNavigationBar else { return }

        if cancelButton == nil {
            navigationBar.items?.forEach { $0.leftBarButtonItem = nil }

            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Cancel", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
            view.addSubview(button)

            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
            ])

            cancelButton = button
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
    
    func setStatesOfTaskListChoiceButtons() {
        var winningButton: UIButton?
        var losingButton: UIButton?
        
        if self.newTaskTaskListId == TaskListIds.Today {
            winningButton = self.todayButton
            losingButton = self.backlogButton
        } else {
            winningButton = self.backlogButton
            losingButton = self.todayButton
        }
        
        winningButton!.isSelected = true
        losingButton!.isSelected = false
    }
    
    func createTask() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let newTaskPosition = getNewTaskPosition()
        if newTaskTaskListId == nil || newTaskPosition == nil {
            self.alert("Missing context for new task")
        }
        
        if !nameField.isValidText() {
            self.alert("Invalid task name")
            return false
        }
        
        let managedContext = appDelegate.getManagedContext()
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        if let task = NSManagedObject(entity: entity, insertInto: managedContext) as? Task {
            task.setNewRecordValues(taskListId: newTaskTaskListId!, position: newTaskPosition!, name: nameField.getTrimmedText())
            do {
                try appDelegate.saveContext()
            } catch {
                self.alert("Unable to save new task")
                return false
            }
            return true
        }
        
        self.alert("Unable to create task")
        return false
    }
    
    func getNewTaskPosition() -> Int? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        if (newTaskTaskListId == nil) {
            return nil
        }

        return 1 + appDelegate.getManagedContext().getHighestVisibleTaskPosition(in: newTaskTaskListId!)
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
