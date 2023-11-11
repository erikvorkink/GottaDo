import UIKit
import CoreData

class DebugTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return "" }
        let managedContext = appDelegate.getManagedContext()

        let todayTasks = managedContext.getOustandingVisibleTasks(in: TaskListIds.Today)
        let backlogTasks = managedContext.getOustandingVisibleTasks(in: TaskListIds.Backlog)
        let completedTasks = managedContext.getCompletedTasks()

        let todayList = outstandingTasksToFormattedList(todayTasks)
        let backlogList = outstandingTasksToFormattedList(backlogTasks)
        let completedList = completedTasksToFormattedList(completedTasks)
        
        let formatted = "[Today]\(todayList)\n\n[Backlog]\(backlogList)\n\n[Completed]\(completedList)"
//        print(formatted)
        return formatted
    }
    
    func outstandingTasksToFormattedList(_ tasks: Array<NSManagedObject>) -> String {
        return tasks.map { "\n- \($0.value(forKey: "name") ?? "")" }.joined()
    }
    
    func completedTasksToFormattedList(_ tasks: Array<NSManagedObject>) -> String {
        return tasks.map { "\n- \($0.value(forKey: "name") ?? "") (\(taskCompletedDateFormatted($0)))" }.joined()
    }
    
    func taskCompletedDateFormatted(_ task: NSManagedObject) -> String {
        var completedDateFormatted = ""
        let completedDate = task.value(forKeyPath: "completedDate") as? Date
        if let completedDate = completedDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale(identifier: "en_US")
            completedDateFormatted = dateFormatter.string(from: completedDate)
        }
        return completedDateFormatted
    }
    
    func deleteOldCompletedTasks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let operation = appDelegate.getManagedContext().deleteOldCompletedTasks
        deleteTasks(alertTitle: "Delete Old Completed Tasks", deleteOperation: operation)
        HapticHelper.generateBigFeedback()
    }
    
    func deleteAllTasks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let operation = appDelegate.getManagedContext().deleteAllTasks
        deleteTasks(alertTitle: "Delete ALL Tasks", deleteOperation: operation)
        HapticHelper.generateBigFeedback()
    }
    
    func deleteTasks(alertTitle: String, deleteOperation: @escaping () -> Void) {
        let dialogMessage = UIAlertController(title: alertTitle, message: "This cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in

            deleteOperation()
            NotificationCenter.default.post(name: NSNotification.Name("bulkTasksDeleted"), object: nil)
            
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
