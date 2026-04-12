import CoreData

final class TaskListService {
    private let managedContext: NSManagedObjectContext
    private let saveContext: () throws -> Void

    init(managedContext: NSManagedObjectContext, saveContext: @escaping () throws -> Void) {
        self.managedContext = managedContext
        self.saveContext = saveContext
    }

    func visibleTasks(in taskListId: TaskListIds) -> [Task] {
        return managedContext.getVisibleTasks(in: taskListId).compactMap { $0 as? Task }
    }

    func outstandingVisibleTaskCount(in taskListId: TaskListIds) -> Int {
        return managedContext.getOutstandingVisibleTaskCount(in: taskListId)
    }

    func move(_ task: Task, from currentTaskListId: TaskListIds) throws {
        let destinationTaskListId: TaskListIds = currentTaskListId == .Backlog ? .Today : .Backlog

        if destinationTaskListId == .Today {
            task.setPosition(1 + managedContext.getHighestVisibleTaskPosition(in: destinationTaskListId))
        } else {
            incrementPositionsOfVisibleTasks(in: destinationTaskListId)
            task.setPosition(1)
        }

        task.setTaskListId(destinationTaskListId)
        try saveContext()
    }

    func toggleFlagged(_ task: Task) throws {
        task.toggleFlagged()
        try saveContext()
    }

    func toggleCompleted(_ task: Task) throws {
        if task.completed {
            task.uncomplete()
        } else {
            task.complete()
        }

        try saveContext()
    }

    func smartSort(_ tasks: [Task]) throws {
        let completedTasks = tasks.filter(\.completed)
        let flaggedTasks = tasks.filter { !$0.completed && $0.flagged }
        let unflaggedTasks = tasks.filter { !$0.completed && !$0.flagged }

        let sortedTasks = completedTasks + flaggedTasks + unflaggedTasks
        syncPositions(for: sortedTasks)
        try saveContext()
    }

    func removeCompleted(in taskListId: TaskListIds) throws {
        let completedTasks = managedContext.getCompletedVisibleTasks(in: taskListId).compactMap { $0 as? Task }
        for task in completedTasks {
            task.remove()
        }

        try saveContext()
    }

    func persistOrder(for tasks: [Task]) throws {
        syncPositions(for: tasks)
        try saveContext()
    }

    private func incrementPositionsOfVisibleTasks(in taskListId: TaskListIds) {
        let tasks = managedContext.getVisibleTasks(in: taskListId).compactMap { $0 as? Task }
        for task in tasks {
            task.setPosition(1 + Int(task.position))
        }
    }

    private func syncPositions(for tasks: [Task]) {
        for (index, task) in tasks.enumerated() {
            task.setPosition(index + 1)
        }
    }
}
