import UIKit
import CoreData

class TaskAddViewController: UIViewController {
    
    var newTaskTaskListId: TaskListIds? // TODO: use a struct for these two?
    var newTaskPosition: Int?
    
    @IBOutlet weak var nameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
    }
    
    @IBAction func cancel(_ sender: Any) {
        close()
    }
    
    @objc
    func createTaskAndClose() {
        if createTask() {
            close()
        }
        // TODO: display error otherwise
    }

    func initEditor() {
        nameField.attributedPlaceholder = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])

        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        nameField.leftView = paddingView
        nameField.leftViewMode = .always

        // Open keyboard right away
        nameField.becomeFirstResponder()

        nameField.addTarget(self, action: #selector(createTaskAndClose), for: .editingDidEndOnExit)
    }
    
    func createTask() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let newTaskName = nameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if !isValidTaskName(newTaskName) {
            return false
        }
        
        let managedContext = appDelegate.getManagedContext()
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        if let task = NSManagedObject(entity: entity, insertInto: managedContext) as? Task {
            // TODO: verify that newTaskPosition has been set
            task.setNewRecordValues(taskListId: newTaskTaskListId as! TaskListIds, position: newTaskPosition as! Int, name: newTaskName)
            appDelegate.saveContext()
            return true
        }
        
        return false
    }
    
    func isValidTaskName(_ name: String) -> Bool {
        // TODO: move this into some shared validation place between this and task edit
        return name.count > 0
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
