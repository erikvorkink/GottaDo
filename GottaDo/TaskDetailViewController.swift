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
        updateTaskDetails()
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
        
        editName.text = task.name
        if let completed = task.value(forKey: "completed") as? Bool {
            completeButton.isHidden = completed
            uncompleteButton.isHidden = !completed
        }
    }
    
    func updateTaskDetails() {
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
