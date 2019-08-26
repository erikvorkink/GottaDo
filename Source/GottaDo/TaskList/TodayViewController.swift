import UIKit

class TodayViewController: TaskListViewController {

    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentTaskListId = TaskListIds.Today
    }

    override func startReorder() {
        super.startReorder()
        addButton.isHidden = true
    }
    
    override func stopReorder() {
        super.stopReorder()
        addButton.isHidden = false
    }
}
