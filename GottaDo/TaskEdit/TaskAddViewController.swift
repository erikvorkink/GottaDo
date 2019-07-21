import UIKit
import CoreData

class TaskAddViewController: UIViewController {
    
    var newTaskTaskListId: TaskListIds?
    var newTaskPosition: Int?
    
    @IBOutlet weak var nameField: TaskNameField!
    @IBOutlet weak var todayButton: UIButton!
    @IBOutlet weak var backlogButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
        setStatesOfTaskListChoiceButtons()
    }
    
    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
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
            close()
        }
    }

    func initEditor() {
        nameField.becomeFirstResponder()
        nameField.addTarget(self, action: #selector(createTaskAndClose), for: .editingDidEndOnExit)
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
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
