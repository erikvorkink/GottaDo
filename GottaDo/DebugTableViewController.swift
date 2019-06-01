import UIKit

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
            deleteTasks()
        default:
            break
        }
    }
    
    func copyTasksToClipboard() {
        print("copyTasksToClipboard")
    }
    
    func deleteTasks() {
        let dialogMessage = UIAlertController(title: "Delete All Tasks", message: "This cannot be undone.", preferredStyle: .alert)
        
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appDelegate.getManagedContext().deleteAllTasks()
            
            let alert = UIAlertController(title: "Delete All Tasks", message: "Tasks have been deleted.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in }
        dialogMessage.addAction(delete)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
}
