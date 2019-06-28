import UIKit

class TaskNameField: UITextField {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initAppearance()
    }
    
    func initAppearance() {
        self.attributedPlaceholder = NSAttributedString(string: "I've gotta...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        self.selectedTextRange = self.textRange(from: self.endOfDocument, to: self.endOfDocument)
        
        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
