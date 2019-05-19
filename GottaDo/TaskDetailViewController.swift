import UIKit

class TaskDetailViewController: UIViewController {

    var task: Task?
    
    @IBOutlet weak var editName: UITextField!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var uncompleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
    }
    
    @IBAction func cancel(_ sender: Any) {
        close()
    }
    
    @IBAction func save(_ sender: Any) {
        saveNameAndClose()
    }
    
    @objc
    func saveNameAndClose() {
        saveName()
        close()
    }
    
    @IBAction func complete(_ sender: Any) {
        completeTask()
        close()
    }

    @IBAction func uncomplete(_ sender: Any) {
        uncompleteTask()
        close()
    }
    
    @IBAction func remove(_ sender: Any) {
        removeTask()
        close()
    }
    
    func initEditor() {
        guard let task = task as Task? else { return }
        
        editName.attributedPlaceholder = NSAttributedString(string: "Do something...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        editName.text = task.name
        
        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        editName.leftView = paddingView
        editName.leftViewMode = .always
        
        // Open keyboard right away
        editName.becomeFirstResponder()
        editName.selectedTextRange = editName.textRange(from: editName.endOfDocument, to: editName.endOfDocument)
        
        editName.addTarget(self, action: #selector(saveNameAndClose), for: .editingDidEndOnExit)

        completeButton.isHidden = task.completed
        uncompleteButton.isHidden = !task.completed
    }
    
    func saveName() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.setName(editName.text as String? ?? "")
        appDelegate.saveContext()
    }
    
    func completeTask() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.complete()
        appDelegate.saveContext()
    }
    
    func uncompleteTask() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.uncomplete()
        appDelegate.saveContext()
    }
    
    func removeTask() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.remove()
        appDelegate.saveContext()
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
