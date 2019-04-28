import UIKit
import CoreData

class BacklogViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var tasks: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Backlog"
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFilteredData()
    }
    
    func loadFilteredData() {
        tasks.removeAll()
        
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "removed != %@", NSNumber(value: true))
        
        do {
            tasks = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }
    
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let task = tasks[indexPath.row] as? Task {
                    toggleTaskFlagged(task)
                    loadFilteredData()
                }
            }
        }
    }

    @IBAction func addTask(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Task",
                                      message: "Add a new task",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            
            guard let textField = alert.textFields?.first,
                let newTaskName = textField.text else {
                    return
            }
            
            self.createTask(name: newTaskName)
            self.loadFilteredData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func createTask(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        
        let task = NSManagedObject(entity: entity, insertInto: managedContext)
        task.setValue(name, forKeyPath: "name")
        task.setValue(Date(), forKeyPath: "createdDate")
        task.setValue(false, forKeyPath: "completed")
        task.setValue(false, forKeyPath: "removed")
        
        do {
            try managedContext.save()
            tasks.append(task)
        } catch let error as NSError {
            print("Could not create task. \(error), \(error.userInfo)")
        }
    }
        
    func toggleTaskFlagged(_ task: Task) {
        print("toggling:")
        print(task.value(forKey: "name"))
        
        task.setValue(!task.flagged, forKey: "flagged")

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
    
    func completeTask(_ task: Task) {
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
    
    @IBAction func clear(_ sender: Any) {
        removeCompleted()
        loadFilteredData()
    }
    
    func removeCompleted() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "completed == %@ AND removed != %@", NSNumber(value: true), NSNumber(value: true))
        
        do {
            let tasksToRemove = try managedContext.fetch(fetchRequest)
            for task in tasksToRemove as! [Task] {
                task.setValue(true, forKeyPath: "removed")
                task.setValue(Date(), forKeyPath: "removedDate")
                
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not create task. \(error), \(error.userInfo)")
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}

// MARK: - UITableViewDataSource
extension BacklogViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let name = task.value(forKeyPath: "name") as? String
        let createdDateFormatted = getTaskCreatedDateFormatted(task)
        
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: "\(name!) - \(createdDateFormatted)")
        if let completed = task.value(forKeyPath: "completed") as? Bool {
            if completed {
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            }
        }
        cell.textLabel?.attributedText = attributeString;
        
        let flagged = task.value(forKeyPath: "flagged") as? Bool ?? false
        if flagged {
            cell.accessoryView = UIImageView(image: UIImage(named:"flagged"))
        } else {
            cell.accessoryView = .none
        }
        
        return cell
    }
    
    func getTaskCreatedDateFormatted(_ task: NSManagedObject) -> String {
        var createdDateFormatted = ""
        let createdDate = task.value(forKeyPath: "createdDate") as? Date
        if let createdDate = createdDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale(identifier: "en_US")
            createdDateFormatted = dateFormatter.string(from: createdDate)
        }
        return createdDateFormatted
    }
}

// MARK: - UITableViewDelegate
extension BacklogViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let task = tasks[indexPath.row] as? Task {
            self.performSegue(withIdentifier: "taskDetailSegue", sender: task)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? TaskDetailViewController, let taskToSend = sender as? Task {
            viewController.task = taskToSend
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            if !task.completed {
                let completeAction = UIContextualAction(style: .destructive, title: "✔") { (action, view, handler) in
                    self.completeTask(task)
                    self.loadFilteredData()
                }
                completeAction.backgroundColor = .green
                let configuration = UISwipeActionsConfiguration(actions: [completeAction])
                configuration.performsFirstActionWithFullSwipe = true
                return configuration
            }
        }
        
        return UISwipeActionsConfiguration()
    }
}
