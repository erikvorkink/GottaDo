import UIKit

class TaskNameField: UITextField {
    
    var maxLength: Int?

    override func awakeFromNib() {
        delegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initAppearance()
        self.maxLength = 75
    }
    
    func initAppearance() {
        self.attributedPlaceholder = NSAttributedString(string: "I've gotta...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        self.selectedTextRange = self.textRange(from: self.endOfDocument, to: self.endOfDocument)
        
        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func getTrimmedText() -> String {
        return self.text?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    func isValidText() -> Bool {
        return self.getTrimmedText().count > 0
    }
}

extension TaskNameField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.maxLength == nil { return true }
        guard let text = textField.text else { return true }
        
        let newLength = text.count + string.count - range.length
        return newLength <= self.maxLength!
    }
}
