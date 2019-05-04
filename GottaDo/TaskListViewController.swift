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
        refresh()
    }
    
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let task = tasks[indexPath.row] as? Task {
                    toggleTaskFlagged(task)
                    refresh()
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
            self.refresh()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func clear(_ sender: Any) {
        removeCompleted()
        refreshTasks()
    }
    
    func refresh() {
        refreshTasks()
        refreshBadge()
    }
    
    func refreshTasks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        tasks.removeAll()
        tasks = appDelegate.getManagedContext().getVisibleTasks(in: currentTaskListId)
        tableView.reloadData()
    }
    
    func refreshBadge() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.setBadgeNumber(getOutstandingTodayTaskCount())
    }
    
    func getOutstandingTodayTaskCount() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return 0 }
        return appDelegate.getManagedContext().getOutstandingTaskCount(in: TaskListIds.Today)
    }
    
    func createTask(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.getManagedContext()
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
        if let task = NSManagedObject(entity: entity, insertInto: managedContext) as? Task {
            task.setNewRecordValues(taskListId: currentTaskListId, name: name)
            appDelegate.saveContext()
        }
    }
    
    func toggleTaskFlagged(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        task.toggleFlagged()
        appDelegate.saveContext()
    }
    
    func moveTask(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let moveToTaskListId = currentTaskListId.rawValue == TaskListIds.Backlog.rawValue ? TaskListIds.Today : TaskListIds.Backlog
        task.setTaskListId(moveToTaskListId)
        appDelegate.saveContext()
    }
    
    func completeTask(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        task.complete()
        appDelegate.saveContext()
    }
    
    func removeCompleted() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let tasksToRemove = appDelegate.getManagedContext().getCompletedVisibleTasks(in: currentTaskListId)
        for task in tasksToRemove as! [Task] {
            task.remove()
        }
        appDelegate.saveContext()
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
                    self.refresh()
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
                self.refresh()
            }
            moveTaskAction.backgroundColor = .purple
            let configuration = UISwipeActionsConfiguration(actions: [moveTaskAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        
        return UISwipeActionsConfiguration()
    }
}
