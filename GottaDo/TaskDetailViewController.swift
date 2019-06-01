import UIKit

class TaskDetailViewController: UIViewController {

    var task: Task?
    @IBOutlet weak var editName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEditor()
    }
    
    @IBAction func close(_ sender: Any) {
        saveNameAndClose()
    }
    
    @objc
    func saveNameAndClose() {
        saveName()
        close()
    }
    
    @IBAction func remove(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Delete Task", message: "This cannot be undone.", preferredStyle: .alert)
        
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in
            self.remove()
            self.close()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in }
        dialogMessage.addAction(delete)
        dialogMessage.addAction(cancel)

        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func initEditor() {
        guard let task = task as Task? else { return }

        editName.attributedPlaceholder = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        editName.text = task.name
        
        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        editName.leftView = paddingView
        editName.leftViewMode = .always
        
        // Open keyboard right away
        editName.becomeFirstResponder()
        editName.selectedTextRange = editName.textRange(from: editName.endOfDocument, to: editName.endOfDocument)
        
        editName.addTarget(self, action: #selector(saveNameAndClose), for: .editingDidEndOnExit)
    }
    
    func saveName() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.setName(editName.text as String? ?? "")
        appDelegate.saveContext()
    }

    func remove() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let task = task as Task? else { return }
        
        task.remove()
        appDelegate.saveContext()
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
