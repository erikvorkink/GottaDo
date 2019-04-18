import UIKit

class TaskDetailViewController: UIViewController {

    var task: Task?
    
    @IBOutlet weak var editName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let task = task as Task? {
            editName.text = task.name
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        if let task = task as Task? {
            task.setValue(editName.text, forKey: "name")

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not update task. \(error), \(error.userInfo)")
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
