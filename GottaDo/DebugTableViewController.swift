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
        print("deleteTasks")
    }
}
