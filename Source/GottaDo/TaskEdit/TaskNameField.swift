import UIKit

class TaskNameField: UITextView {

    private let baseTextInset = UIEdgeInsets(top: 18, left: 8, bottom: 18, right: 8)
    private let caretColor = UIColor.systemBlue

    var maxLength: Int?
    var onSubmit: (() -> Void)?

    private let placeholderLabel = UILabel()
    private let fakeCaretView = UIView()
    private var placeholderCenterYConstraint: NSLayoutConstraint?
    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
            updateFakeCaretAppearance()
        }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    private func commonInit() {
        delegate = self
        maxLength = 100
        initAppearance()
        updatePlaceholderVisibility()
    }

    private func initAppearance() {
        backgroundColor = .clear
        textContainerInset = baseTextInset
        textContainer.lineFragmentPadding = 0

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "I've gotta..."
        placeholderLabel.textColor = .lightGray
        placeholderLabel.numberOfLines = 0
        placeholderLabel.font = font
        placeholderLabel.textAlignment = textAlignment
        addSubview(placeholderLabel)

        fakeCaretView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fakeCaretView)
        updateFakeCaretAppearance()

        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -textContainerInset.right)
        ])

        placeholderCenterYConstraint = placeholderLabel.centerYAnchor.constraint(equalTo: topAnchor, constant: 0)
        placeholderCenterYConstraint?.isActive = true

        NSLayoutConstraint.activate([
            fakeCaretView.trailingAnchor.constraint(equalTo: placeholderLabel.leadingAnchor, constant: -2),
            fakeCaretView.centerYAnchor.constraint(equalTo: placeholderLabel.centerYAnchor),
            fakeCaretView.widthAnchor.constraint(equalToConstant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateFakeCaretAppearance()
        updatePlaceholderPosition()
    }

    override var text: String! {
        didSet {
            updatePlaceholderVisibility()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            updatePlaceholderVisibility()
        }
    }

    func getTrimmedText() -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isValidText() -> Bool {
        getTrimmedText().isEmpty == false
    }

    private func updatePlaceholderVisibility() {
        let showsEmptyState = text.isEmpty
        placeholderLabel.isHidden = showsEmptyState == false
        fakeCaretView.isHidden = showsEmptyState == false || isFirstResponder == false
        tintColor = showsEmptyState ? .clear : caretColor

        if fakeCaretView.isHidden {
            fakeCaretView.layer.removeAnimation(forKey: "blink")
        } else {
            startFakeCaretBlinking()
        }
    }

    private func updateFakeCaretAppearance() {
        let lineHeight = font?.lineHeight ?? 28
        fakeCaretView.backgroundColor = caretColor
        fakeCaretView.layer.cornerRadius = 1

        if let heightConstraint = fakeCaretView.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = lineHeight
        } else {
            fakeCaretView.heightAnchor.constraint(equalToConstant: lineHeight).isActive = true
        }
    }

    private func updatePlaceholderPosition() {
        let lineHeight = font?.lineHeight ?? 28
        placeholderCenterYConstraint?.constant = textContainerInset.top + (lineHeight / 2)
    }

    private func startFakeCaretBlinking() {
        guard fakeCaretView.layer.animation(forKey: "blink") == nil else { return }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        fakeCaretView.layer.add(animation, forKey: "blink")
    }

    override func becomeFirstResponder() -> Bool {
        let becameFirstResponder = super.becomeFirstResponder()
        updatePlaceholderVisibility()
        return becameFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let resignedFirstResponder = super.resignFirstResponder()
        updatePlaceholderVisibility()
        return resignedFirstResponder
    }
}

extension TaskNameField: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            onSubmit?()
            return false
        }

        if text.contains(where: \.isNewline) {
            return false
        }

        guard let maxLength, let currentText = textView.text, let textRange = Range(range, in: currentText) else {
            return true
        }

        let updatedText = currentText.replacingCharacters(in: textRange, with: text)
        return updatedText.count <= maxLength
    }
}
