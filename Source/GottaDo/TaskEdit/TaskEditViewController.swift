import UIKit

class TaskEditViewController: UIViewController {

    var task: Task?
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
    
    @IBAction func close(_ sender: Any) {
        saveNameAndClose()
    }
    
    @objc
    func saveNameAndClose() {
        if saveName() {
            closeKeyboard()
            close()
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Delete Task", message: "This can't be undone.", preferredStyle: .alert)
        
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in
            if self.remove() {
                self.close()
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in }
        dialogMessage.addAction(delete)
        dialogMessage.addAction(cancel)

        self.closeKeyboard()
        self.present(dialogMessage, animated: true, completion: nil)
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
