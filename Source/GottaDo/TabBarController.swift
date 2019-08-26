import UIKit

class TabBarController: UITabBarController {
    
    let longPressRightEdgeThreshold = 40

    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tabBar.addGestureRecognizer(longPressRecognizer)
    }
    
    // Long press opens Debug view
    @objc
    func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if self.touchedCloseToRightEdge(touchPoint) {
                performSegue(withIdentifier: "debugSegue", sender: nil)
            }
        }
    }
    
    func touchedCloseToRightEdge(_ touchPoint: CGPoint) -> Bool {
        let touchPointX = Float(touchPoint.x)
        let frameWidth = Float(self.view.frame.size.width)
        return frameWidth - touchPointX <= Float(self.longPressRightEdgeThreshold)
    }
}
