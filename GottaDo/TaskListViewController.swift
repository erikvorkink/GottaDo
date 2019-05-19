import UIKit
import CoreData

class TaskListViewController: UIViewController {
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var reorderButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var currentTaskListId = TaskListIds.Today
    var tasks: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.rowHeight = 50.0
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    // Load/refresh data
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    // Get out of reorder mode when switching away
    override func viewWillDisappear(_ animated: Bool) {
        stopReorder()
    }
    
    // Flag/unflag task upon long press
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let task = tasks[indexPath.row] as? Task {
                    toggleTaskFlagged(task)
                    refresh()
                }
            }
        }
    }
    
    // New task
    @IBAction func addTask(_ sender: UIButton) {
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
    
    // Remove completed tasks from list
    @IBAction func clear(_ sender: Any) {
        removeCompleted()
        refreshTasks()
    }
    
    // Toggle reorder mode
    @IBAction func toggleReorder(_ sender: Any) {
        if tableView.isEditing {
            stopReorder()
        } else {
            startReorder()
        }
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
        
        if tasks.count > 0 {
            handlePopulatedTaskList()
        } else {
            handleEmptyTaskList()
        }
    }
    
    func handlePopulatedTaskList() {
        hideBlankState()
        clearButton.isHidden = false
        reorderButton.isHidden = false
    }
    
    func handleEmptyTaskList() {
        showBlankState("Nothing to do")
        clearButton.isHidden = true
        reorderButton.isHidden = true
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
            task.setNewRecordValues(taskListId: currentTaskListId, position: getNewTaskPosition(), name: name)
            appDelegate.saveContext()
        }
    }
    
    // Determine the position value a new task should get?
    func getNewTaskPosition() -> Int {
        if let lastTask = tasks.last as? Task {
            if let lastTaskPosition = lastTask.value(forKey: "position") as? Int {
                return 1 + lastTaskPosition
            }
        }
        return 1
    }
    
    // Move from Today <--> Backlog
    func moveTask(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let moveToTaskListId = currentTaskListId.rawValue == TaskListIds.Backlog.rawValue ? TaskListIds.Today : TaskListIds.Backlog
        task.setTaskListId(moveToTaskListId)
        appDelegate.saveContext()
    }
    
    func toggleTaskFlagged(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        task.toggleFlagged()
        appDelegate.saveContext()
    }
    
    func toggleTaskComplete(_ task: Task) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        if task.completed {
            task.uncomplete()
        } else {
            task.complete()
        }
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
    
    func startReorder() {
        tableView.isEditing = true
    }
    
    func stopReorder() {
        tableView.isEditing = false
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
    
    // Row for each task
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    // Render task row
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        if let task = tasks[indexPath.row] as? Task {
            cell.textLabel?.font = UIFont.init(name: "Helvetica", size: 20)
            cell.textLabel?.textColor = UIColor(white: 0.2, alpha: 1.0)
            cell.textLabel?.attributedText = getCellAttributedText(task);
            cell.accessoryView = (task.flagged) ?UIImageView(image: UIImage(named:"flagged")) : .none
        }
        return cell
    }
    
    func getCellAttributedText(_ task: Task) -> NSMutableAttributedString {
        let name = task.name ?? ""
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: name)
        if task.completed {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
        }
        return attributeString
    }
    
    // No delete icon when reordering
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none;
    }
    
    // No indent when reordering
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // All rows can be reordered
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Persist a reordered task
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let taskToReorder = tasks[sourceIndexPath.row]
        tasks.remove(at: sourceIndexPath.row)
        tasks.insert(taskToReorder, at: destinationIndexPath.row)
        
        syncTaskPositionsToOrderInArray()
        appDelegate.saveContext()
    }
    
    // Set the position value of each task so that it matches the current position in the tasks array
    func syncTaskPositionsToOrderInArray() {
        var nextPosition = 1
        for task in tasks as! [Task] {
            task.setPosition(nextPosition)
            nextPosition += 1
        }
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
    
    func showBlankState(_ message: String) {
        let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "Helvetica", size: 20)
        emptyView.addSubview(messageLabel)
        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        tableView.backgroundView = emptyView
        tableView.separatorStyle = .none
    }
    
    func hideBlankState() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }
    
    // Selecting task opens up the detail view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let task = tasks[indexPath.row] as? Task {
            self.performSegue(withIdentifier: "taskDetailSegue", sender: task)
        }
    }
    
    // Send task to the detail view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? TaskDetailViewController, let taskToSend = sender as? Task {
            viewController.task = taskToSend
        }
    }
    
    // Swipe right to complete/uncomplete
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let title = (task.completed) ? "Restore" : "Complete"
            let action = UIContextualAction(style: .normal, title: title) { (action, view, handler) in
                self.toggleTaskComplete(task)
                self.refresh()
            }
            action.backgroundColor = UIColor(red: 0.25, green: 0.38, blue: 0.25, alpha: 1.0)
            let configuration = UISwipeActionsConfiguration(actions: [action])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return UISwipeActionsConfiguration()
    }
    
    // Swipe left to move between Today and Backlog
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let title = (currentTaskListId == TaskListIds.Today) ? "Backlog" : "Today"
            let moveTaskAction = UIContextualAction(style: .normal, title: title) { (action, view, handler) in
                self.moveTask(task)
                self.refresh()
            }
            moveTaskAction.backgroundColor = UIColor(red: 0.33, green: 0.19, blue: 0.38, alpha: 1.0)
            let configuration = UISwipeActionsConfiguration(actions: [moveTaskAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return UISwipeActionsConfiguration()
    }
}
