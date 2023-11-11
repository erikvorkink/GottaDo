import UIKit

class TaskEditViewController: UIViewController {

    var task: Task?
    @IBOutlet weak var nameField: TaskNameField!
    
    let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initEditor()
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
            generateBigHapticFeedback()
            self.closeKeyboard()
            self.close()
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        if self.remove() {
            NotificationCenter.default.post(name: NSNotification.Name("taskDeletedByModal"), object: nil)
            generateBigHapticFeedback()
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
    
    func generateBigHapticFeedback() {
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
}
