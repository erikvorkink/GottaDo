import UIKit

class BacklogViewController: TaskListViewController {

    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentTaskListId = TaskListIds.Backlog
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
