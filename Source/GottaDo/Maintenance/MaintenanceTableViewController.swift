import UIKit
import CoreData

class MaintenanceTableViewController: UITableViewController {
    private let recentClearedLimit = 30
    private let actionItems = [
        "Copy tasks to clipboard",
        "Delete old completed tasks",
        "Delete ALL tasks"
    ]

    var appContext: AppContext?
    private var recentlyClearedTasks: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MaintenanceActionCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshRecentlyClearedTasks()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 0 else { return }

        switch indexPath.row {
        case 0:
            copyTasksToClipboard()
        case 1:
            deleteOldCompletedTasks()
        case 2:
            deleteAllTasks()
        default:
            break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return actionItems.count
        }

        return max(recentlyClearedTasks.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Actions" : "Recently Cleared"
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MaintenanceActionCell", for: indexPath)
            cell.textLabel?.attributedText = nil
            cell.textLabel?.text = actionItems[indexPath.row]
            cell.textLabel?.textColor = indexPath.row == 2 ? .red : UIColor(white: 0.1, alpha: 1.0)
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .default
            return cell
        }

        let cell = UITableViewCell(style: .default, reuseIdentifier: "RecentlyClearedCell")
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none

        if recentlyClearedTasks.isEmpty {
            cell.textLabel?.text = "No recently cleared items"
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.attributedText = nil
            return cell
        }

        let task = recentlyClearedTasks[indexPath.row]
        cell.textLabel?.attributedText = recentlyClearedAttributedText(for: task)
        cell.textLabel?.textColor = UIColor(white: 0.55, alpha: 1.0)
        return cell
    }

    private func refreshRecentlyClearedTasks() {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return }

        recentlyClearedTasks = appContext.managedContext
            .getRecentlyRemovedCompletedTasks(limit: recentClearedLimit)
            .compactMap { $0 as? Task }
        tableView.reloadData()
    }
    
    func copyTasksToClipboard() {
        let formattedTaskList = getFormattedTaskList()
        if formattedTaskList.count == 0 {
            let alert = UIAlertController(title: "Unable to Copy Tasks", message: "", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        UIPasteboard.general.string = formattedTaskList
        
        HapticHelper.generateBigFeedback()
        
        let alert = UIAlertController(title: "Copy Tasks", message: "Tasks have been copied to the clipboard.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
     [Today]
     - first
     - second
     
     [Backlog]
     - third
     - fourth
     
     [Completed]
     - fifth
     - sixth
     */
    func getFormattedTaskList() -> String {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return "" }
        let managedContext = appContext.managedContext

        let todayTasks = managedContext.getOutstandingVisibleTasks(in: TaskListIds.Today)
        let backlogTasks = managedContext.getOutstandingVisibleTasks(in: TaskListIds.Backlog)
        let completedTasks = managedContext.getCompletedTasks()

        let todayList = outstandingTasksToFormattedList(todayTasks)
        let backlogList = outstandingTasksToFormattedList(backlogTasks)
        let completedList = completedTasksToFormattedList(completedTasks)
        
        let formatted = "[Today]\(todayList)\n\n[Backlog]\(backlogList)\n\n[Completed]\(completedList)"
//        print(formatted)
        return formatted
    }
    
    func outstandingTasksToFormattedList(_ tasks: [NSManagedObject]) -> String {
        return tasks.map { "\n- \($0.value(forKey: "name") ?? "")" }.joined()
    }

    func completedTasksToFormattedList(_ tasks: [NSManagedObject]) -> String {
        return tasks.map { "\n- \($0.value(forKey: "name") ?? "") (\(taskCompletedDateFormatted($0)))" }.joined()
    }
    
    func taskCompletedDateFormatted(_ task: NSManagedObject) -> String {
        let completedDate = task.value(forKeyPath: "completedDate") as? Date
        return taskDateFormatted(completedDate)
    }

    func taskDateFormatted(_ date: Date?) -> String {
        guard let date = date else { return "recently" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: date)
    }

    func recentlyClearedAttributedText(for task: Task) -> NSAttributedString {
        let name = task.name ?? ""
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.55, alpha: 1.0),
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
        return NSAttributedString(string: name, attributes: attributes)
    }
    
    func deleteOldCompletedTasks() {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return }
        
        let operation = appContext.managedContext.deleteOldCompletedTasks
        deleteTasks(alertTitle: "Delete Old Completed Tasks", deleteOperation: operation)
        HapticHelper.generateBigFeedback()
    }
    
    func deleteAllTasks() {
        let appContext = self.appContext ?? UIApplication.shared.appContext
        self.appContext = appContext
        guard let appContext else { return }
        
        let operation = appContext.managedContext.deleteAllTasks
        deleteTasks(alertTitle: "Delete ALL Tasks", deleteOperation: operation)
        HapticHelper.generateBigFeedback()
    }
    
    func deleteTasks(alertTitle: String, deleteOperation: @escaping () -> Void) {
        let dialogMessage = UIAlertController(title: alertTitle, message: "This cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in

            deleteOperation()
            self.refreshRecentlyClearedTasks()
            NotificationCenter.default.post(name: .bulkTasksDeleted, object: nil)
            
            let alert = UIAlertController(title: alertTitle, message: "Tasks have been deleted.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in }
        dialogMessage.addAction(delete)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }

}
