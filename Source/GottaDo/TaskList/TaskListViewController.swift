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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    // Get out of reorder mode when switching away
    override func viewWillDisappear(_ animated: Bool) {
        stopReorder()
    }
    
    // Get out of reorder mode when moving app to background
    @objc func appMovedToBackground() {
        stopReorder()
    }
    
    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Flag/unflag task upon long press
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let task = tasks[indexPath.row] as? Task {
                    if toggleTaskFlagged(task) {
                        refresh()
                    }
                }
            }
        }
    }
    
    // Remove completed tasks from list
    @IBAction func clear(_ sender: Any) {
        if removeCompleted() {
            refreshTasks()
        }
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
        clearButton.isHidden = !listContainsCompletedTasks()
        reorderButton.isHidden = tasks.count < 2
    }
    
    func handleEmptyTaskList() {
        showBlankState("Nothing to do")
        clearButton.isHidden = true
        reorderButton.isHidden = true
    }
    
    func listContainsCompletedTasks() -> Bool {
        for task in tasks as! [Task] {
            if task.completed {
                return true
            }
        }
        return false
    }
    
    func refreshBadge() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.setBadgeNumber(getOutstandingTodayTaskCount())
    }
    
    func getOutstandingTodayTaskCount() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return 0 }
        return appDelegate.getManagedContext().getOutstandingVisibleTaskCount(in: TaskListIds.Today)
    }
    
    // Move from Today <--> Backlog
    func moveTask(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let moveToTaskListId = currentTaskListId.rawValue == TaskListIds.Backlog.rawValue ? TaskListIds.Today : TaskListIds.Backlog
        
        if moveToTaskListId == TaskListIds.Today {
            // Backlog -> Today = bottom of list
            task.setPosition(1 + appDelegate.getManagedContext().getHighestVisibleTaskPosition(in: moveToTaskListId))
        } else {
            // Today -> Backlog = top of list
            incrementPositionOfVisibleTasksInGivenList(moveToTaskListId)
            task.setPosition(1)
        }
        
        task.setTaskListId(moveToTaskListId) // wait until position has been determined
        
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to move task")
            return false
        }
        return true
    }
    
    // Used to insert a Today -> Backlog task at the top of the list
    func incrementPositionOfVisibleTasksInGivenList(_ taskListId: TaskListIds) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let tasks = appDelegate.getManagedContext().getVisibleTasks(in: taskListId)
        for task in tasks as! [Task] {
            task.setPosition(1 + Int(task.position))
        }
    }
    
    func toggleTaskFlagged(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        task.toggleFlagged()
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to toggle flagged")
            return false
        }
        return true
    }
    
    func toggleTaskComplete(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }

        if task.completed {
            task.uncomplete()
        } else {
            task.complete()
        }
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to toggle completed")
            return false
        }
        return true
    }
    
    func removeCompleted() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let tasksToRemove = appDelegate.getManagedContext().getCompletedVisibleTasks(in: currentTaskListId)
        for task in tasksToRemove as! [Task] {
            task.remove()
        }
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to remove completed tasks")
            return false
        }
        return true
    }
    
    func startReorder() {
        tableView.isEditing = true
        reorderButton.setImage(UIImage(named: "reorder-active"), for: .normal)
    }
    
    func stopReorder() {
        tableView.isEditing = false
        reorderButton.setImage(UIImage(named: "reorder"), for: .normal)
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
            cell.textLabel?.textColor = UIColor(white: task.completed ? 0.7 : 0.2, alpha: 1.0) // lighter gray once completed
            cell.textLabel?.attributedText = getCellAttributedText(task);
            cell.textLabel?.numberOfLines = 0 // activate text wrapping
            
            if task.flagged {
                let flagImageName = task.completed ? "flagged-faded" : "flagged"
                let flagImage = UIImageView(image: UIImage(named: flagImageName))
                cell.accessoryView = flagImage
            } else {
                cell.accessoryView = .none
            }
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
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to save new order")
        }
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
    
    // Selecting task opens up the edit view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let task = tasks[indexPath.row] as? Task {
            self.performSegue(withIdentifier: "taskEditSegue", sender: task)
        }
    }
    
    // Swipe right to complete/uncomplete
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let title = (task.completed) ? "Restore" : "Complete"
            let action = UIContextualAction(style: .normal, title: title) { (action, view, handler) in
                if self.toggleTaskComplete(task) {
                    self.refresh()
                }
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
                if self.moveTask(task) {
                    self.refresh()
                }
            }
            moveTaskAction.backgroundColor = UIColor(red: 0.33, green: 0.19, blue: 0.38, alpha: 1.0)
            let configuration = UISwipeActionsConfiguration(actions: [moveTaskAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return UISwipeActionsConfiguration()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "taskAddSegue":
            // Pass context needed by a new task
            if let viewController = segue.destination as? TaskAddViewController {
                viewController.newTaskTaskListId = currentTaskListId
            }
        case "taskEditSegue":
            // Pass the task to edit
            if let viewController = segue.destination as? TaskEditViewController, let taskToSend = sender as? Task {
                viewController.task = taskToSend
            }
        default:
            break;
        }
    }
}
