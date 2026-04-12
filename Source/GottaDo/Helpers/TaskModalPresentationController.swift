import UIKit

final class TaskModalPresentationController: UIPresentationController {
    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDimmingViewTapped)))
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }

        let bounds = containerView.bounds
        let targetHeight = bounds.height * 0.75
        let safeBottomInset = containerView.safeAreaInsets.bottom
        let yOffset = bounds.height - targetHeight

        return CGRect(
            x: 0,
            y: yOffset,
            width: bounds.width,
            height: min(targetHeight + safeBottomInset, bounds.height)
        )
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else { return }

        dimmingView.frame = containerView.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.insertSubview(dimmingView, at: 0)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 24
        presentedView?.layer.cornerCurve = .continuous
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView?.clipsToBounds = true
    }

    @objc
    private func handleDimmingViewTapped() {
        presentedViewController.dismiss(animated: true)
    }
}

final class TaskModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.18
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)

        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else {
                transitionContext.completeTransition(false)
                return
            }

            let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
            transitionContext.containerView.addSubview(toView)

            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
                toView.frame = finalFrame
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }

            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn]) {
                fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
}

final class TaskModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = TaskModalTransitioningDelegate()

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        TaskModalPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        TaskModalTransitionAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        TaskModalTransitionAnimator(isPresenting: false)
    }
}
