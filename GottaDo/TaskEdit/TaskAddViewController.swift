import UIKit
import CoreData

class TaskAddViewController: UIViewController {
    
    var newTaskTaskListId: TaskListIds? // TODO: use a struct for these two?
    var newTaskPosition: Int?
    
    @IBOutlet weak var nameField: TaskNameField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
    }
    
    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        close()
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
    
    func createTask() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        if !nameField.isValidText() {
            self.alert("Invalid task name")
            return false
        }
        
        let managedContext = appDelegate.getManagedContext()
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        if let task = NSManagedObject(entity: entity, insertInto: managedContext) as? Task {
            task.setNewRecordValues(taskListId: newTaskTaskListId as! TaskListIds, position: newTaskPosition as! Int, name: nameField.getTrimmedText())
            do {
                try appDelegate.saveContext()
            } catch {
                self.alert("Unable to create task")
                return false
            }
            return true
        }
        return false
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
