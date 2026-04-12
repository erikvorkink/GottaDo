import UIKit

class TaskNameField: UITextField {
    
    var maxLength: Int?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        delegate = self
        maxLength = 75
        initAppearance()
    }
    
    func initAppearance() {
        self.attributedPlaceholder = NSAttributedString(string: "I've gotta...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])

        // Extra padding since the field goes to the edges
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        self.leftView = paddingView
        self.leftViewMode = .always
        self.rightView = paddingView
        self.rightViewMode = .always
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
