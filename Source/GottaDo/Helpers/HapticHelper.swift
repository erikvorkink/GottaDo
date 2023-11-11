import UIKit

class HapticHelper {
    private static var impactGenerator: UIImpactFeedbackGenerator?
    private static var notificationGenerator: UINotificationFeedbackGenerator?
    private static var selectionGenerator: UISelectionFeedbackGenerator?

    static func generateSmallFeedback() {
        self.impactFeedback()
    }
    
    static func generateBigFeedback() {
        self.notificationFeedback(type: .success)
    }
    
    static func impactFeedback() {
        if #available(iOS 10.0, *) {
            impactGenerator = impactGenerator ?? UIImpactFeedbackGenerator()
            impactGenerator?.prepare()
            impactGenerator?.impactOccurred()
        }
    }

    static func notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        if #available(iOS 10.0, *) {
            notificationGenerator = notificationGenerator ?? UINotificationFeedbackGenerator()
            notificationGenerator?.prepare()
            notificationGenerator?.notificationOccurred(type)
        }
    }

    static func selectionFeedback() {
        if #available(iOS 10.0, *) {
            selectionGenerator = selectionGenerator ?? UISelectionFeedbackGenerator()
            selectionGenerator?.prepare()
            selectionGenerator?.selectionChanged()
        }
    }
}
