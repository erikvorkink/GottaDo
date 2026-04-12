import UIKit

class TodayViewController: TaskListViewController {
    override var listTitle: String {
        return "Today"
    }
    
    override func viewDidLoad() {
        currentTaskListId = TaskListIds.Today
        super.viewDidLoad()
    }
}
