import UIKit

class BacklogViewController: TaskListViewController {
    override var listTitle: String {
        return "Backlog"
    }
    
    override func viewDidLoad() {
        currentTaskListId = TaskListIds.Backlog
        super.viewDidLoad()
    }
}
