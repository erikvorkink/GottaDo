import UIKit

final class TaskModalFactory {
    private enum StoryboardIdentifier {
        static let taskAddNavigationController = "TaskAddNavigationController"
        static let taskEditNavigationController = "TaskEditNavigationController"
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

        return navigationController
    }
}
