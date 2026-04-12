import UIKit
import CoreData

class TaskAddViewController: TaskEditorViewController {

    var newTaskTaskListId: TaskListIds?
    var appContext: AppContext?

    override var showsTaskListPicker: Bool {
        return true
    }

    override var selectedTaskListForPicker: TaskListIds? {
        return newTaskTaskListId
    }

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

    @IBAction func cancel(_ sender: Any) {
        closeKeyboard()
        close()
    }

    override func didChangeSelectedTaskList(_ taskListId: TaskListIds) {
        newTaskTaskListId = taskListId
    }

    @objc
    func createTaskAndClose() {
        if createTask() {
            NotificationCenter.default.post(name: .taskCreated, object: nil)
            HapticHelper.generateBigFeedback()
            close()
        }
    }

    func closeKeyboard() {
        nameField.resignFirstResponder()
    }

    func initEditor() {
        nameField.becomeFirstResponder()
        nameField.addTarget(self, action: #selector(createTaskAndClose), for: .editingDidEndOnExit)
    }

    private func configureNavigation() {
        ModalNavigationStyler.apply(to: navigationController)
        navigationItem.title = "Add Task"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancel(_:))
        )
    }

    func createTask() -> Bool {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return false }
        let newTaskPosition = getNewTaskPosition()
        if newTaskTaskListId == nil || newTaskPosition == nil {
            alert("Missing context for new task")
        }

        if !nameField.isValidText() {
            alert("Invalid task name")
            return false
        }

        let managedContext = appContext.managedContext
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        if let task = NSManagedObject(entity: entity, insertInto: managedContext) as? Task {
            task.setNewRecordValues(taskListId: newTaskTaskListId!, position: newTaskPosition!, name: nameField.getTrimmedText())
            do {
                try appContext.saveContext()
            } catch {
                alert("Unable to save new task")
                return false
            }
            return true
        }

        alert("Unable to create task")
        return false
    }

    func getNewTaskPosition() -> Int? {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return nil }
        guard let newTaskTaskListId else { return nil }

        return 1 + appContext.managedContext.getHighestVisibleTaskPosition(in: newTaskTaskListId)
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }
}
