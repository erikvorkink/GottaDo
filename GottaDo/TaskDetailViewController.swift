import UIKit

class TaskDetailViewController: UIViewController {

    var task: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("modal just loaded with this task:")
        print(task)
        // Do any additional setup after loading the view.
    }
}
