import UIKit

class TaskDetailViewController: UIViewController {

    var task: Task?
    
    @IBOutlet weak var editName: UITextField!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var uncompleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let task = task as Task? {
            editName.text = task.name
            
            if let completed = task.value(forKey: "completed") as? Bool {
                completeButton.isHidden = completed
                uncompleteButton.isHidden = !completed
            } else { // TODO: remove this once the data always has this field
                completeButton.isHidden = false
                uncompleteButton.isHidden = true
            }
        }
    }
    
    func updateDetails() {
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
    }
    
    func complete() {
        if let task = task as Task? {
            task.setValue(true, forKey: "completed")
            task.setValue(Date(), forKey: "completedDate")
            
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
    }
    
    func uncomplete() {
        if let task = task as Task? {
            task.setValue(false, forKey: "completed")
            task.setValue(nil, forKey: "completedDate")
            
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
    }
    
    func remove() {
        if let task = task as Task? {
            task.setValue(true, forKey: "removed")
            task.setValue(Date(), forKey: "removedDate")
            
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
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        close()
    }
    
    @IBAction func save(_ sender: Any) {
        updateDetails()
        close()
    }
    
    @IBAction func complete(_ sender: Any) {
        complete()
        close()
    }

    @IBAction func uncomplete(_ sender: Any) {
        uncomplete()
        close()
    }
    
    @IBAction func remove(_ sender: Any) {
        remove()
        close()
    }
}
