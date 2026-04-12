import UIKit

final class TaskModalFactory {
    private enum StoryboardIdentifier {
        static let taskAddNavigationController = "TaskAddNavigationController"
        static let taskEditNavigationController = "TaskEditNavigationController"
    }

    private enum SheetDetentIdentifier {
        static let taskModal = UISheetPresentationController.Detent.Identifier("taskModal")
    }

    private let storyboard: UIStoryboard
    private let appContext: AppContext?

    init(storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil), appContext: AppContext?) {
        self.storyboard = storyboard
        self.appContext = appContext
    }

    func makeTaskAddNavigationController(for taskListId: TaskListIds) -> UINavigationController? {
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: StoryboardIdentifier.taskAddNavigationController) as? UINavigationController else {
            return nil
        }

        if let viewController = navigationController.topViewController as? TaskAddViewController {
            viewController.newTaskTaskListId = taskListId
            viewController.appContext = appContext
        }

        configureSheetPresentation(for: navigationController)

        return navigationController
    }

    func makeTaskEditNavigationController(for task: Task) -> UINavigationController? {
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: StoryboardIdentifier.taskEditNavigationController) as? UINavigationController else {
            return nil
        }

        if let viewController = navigationController.topViewController as? TaskEditViewController {
            viewController.task = task
            viewController.appContext = appContext
        }

        configureSheetPresentation(for: navigationController)

        return navigationController
    }

    private func configureSheetPresentation(for navigationController: UINavigationController) {
        navigationController.modalPresentationStyle = .pageSheet

        guard let sheetPresentationController = navigationController.sheetPresentationController else { return }

        if #available(iOS 16.0, *) {
            let taskDetent = UISheetPresentationController.Detent.custom(identifier: SheetDetentIdentifier.taskModal) { context in
                context.maximumDetentValue * 0.75
            }
            sheetPresentationController.detents = [taskDetent]
            sheetPresentationController.selectedDetentIdentifier = SheetDetentIdentifier.taskModal
        } else {
            sheetPresentationController.detents = [.large()]
        }

        sheetPresentationController.prefersGrabberVisible = true
        sheetPresentationController.preferredCornerRadius = 24
    }
}
