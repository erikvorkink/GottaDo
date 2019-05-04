import UIKit
import CoreData

@objc public enum TaskListIds: Int16 {
    case Today    = 1
    case Backlog  = 2
}

class TaskListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var currentTaskListId = TaskListIds.Today
    var tasks: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func reload() {
        loadFilteredData()
        updateBadgeNumber()
    }
    
    func loadFilteredData() {
        tasks.removeAll()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND removed != %@", NSNumber(value: currentTaskListId.rawValue), NSNumber(value: true))
        
        do {
            tasks = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }
    
    func updateBadgeNumber() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.setBadgeNumber(to: getNumberOfTodayTasks())
    }
    
    func getNumberOfTodayTasks() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return 0
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed != %@", NSNumber(value: currentTaskListId.rawValue), NSNumber(value: true))
        
        do {
            let count = try managedContext.count(for: fetchRequest)
            return count
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return 0
        }
    }
    
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let task = tasks[indexPath.row] as? Task {
                    toggleTaskFlagged(task)
                    reload()
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
            self.reload()
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
        task.setValue(currentTaskListId.rawValue, forKey: "taskListId")
        task.setValue(name, forKey: "name")
        task.setValue(Date(), forKey: "createdDate")
        task.setValue(false, forKey: "completed")
        task.setValue(false, forKey: "removed")
        
        do {
            try managedContext.save()
            tasks.append(task)
        } catch let error as NSError {
            print("Could not create task. \(error), \(error.userInfo)")
        }
    }
    
    func toggleTaskFlagged(_ task: Task) {
        let flagged = task.value(forKey: "flagged") as? Bool ?? false
        task.setValue(!flagged, forKey: "flagged")
        
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
    
    func moveTask(_ task: Task) {
        let moveToTaskListId = currentTaskListId.rawValue == TaskListIds.Backlog.rawValue ? TaskListIds.Today : TaskListIds.Backlog
        
        task.setValue(moveToTaskListId.rawValue, forKey: "taskListId")
        
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
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed == %@ AND removed != %@", NSNumber(value: currentTaskListId.rawValue), NSNumber(value: true), NSNumber(value: true))
        
        do {
            let tasksToRemove = try managedContext.fetch(fetchRequest)
            for task in tasksToRemove as! [Task] {
                task.setValue(true, forKey: "removed")
                task.setValue(Date(), forKey: "removedDate")
                
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
extension TaskListViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let name = task.value(forKey: "name") as? String
        let createdDateFormatted = getTaskCreatedDateFormatted(task)
        
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: "\(name!) - \(createdDateFormatted)")
        if let completed = task.value(forKey: "completed") as? Bool {
            if completed {
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            }
        }
        cell.textLabel?.attributedText = attributeString;
        
        let flagged = task.value(forKey: "flagged") as? Bool ?? false
        if flagged {
            cell.accessoryView = UIImageView(image: UIImage(named:"flagged"))
        } else {
            cell.accessoryView = .none
        }
        
        return cell
    }
    
    func getTaskCreatedDateFormatted(_ task: NSManagedObject) -> String {
        var createdDateFormatted = ""
        let createdDate = task.value(forKey: "createdDate") as? Date
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
extension TaskListViewController: UITableViewDelegate {
    
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
                    self.reload()
                }
                completeAction.backgroundColor = .green
                let configuration = UISwipeActionsConfiguration(actions: [completeAction])
                configuration.performsFirstActionWithFullSwipe = true
                return configuration
            }
        }
        
        return UISwipeActionsConfiguration()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let moveTaskAction = UIContextualAction(style: .destructive, title: "Move") { (action, view, handler) in
                self.moveTask(task)
                self.reload()
            }
            moveTaskAction.backgroundColor = .purple
            let configuration = UISwipeActionsConfiguration(actions: [moveTaskAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        
        return UISwipeActionsConfiguration()
    }
}
