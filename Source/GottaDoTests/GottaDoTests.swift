import CoreData
import XCTest
@testable import GottaDo

final class GottaDoTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!
    private var managedContext: NSManagedObjectContext!
    private var saveCallCount: Int!
    private var taskListService: TaskListService!

    override func setUpWithError() throws {
        try super.setUpWithError()

        persistentContainer = try makeInMemoryPersistentContainer()
        managedContext = persistentContainer.viewContext
        saveCallCount = 0
        taskListService = TaskListService(
            managedContext: managedContext,
            saveContext: { [weak self] in
                self?.saveCallCount += 1
                if self?.managedContext.hasChanges == true {
                    try self?.managedContext.save()
                }
            }
        )
    }

    override func tearDownWithError() throws {
        taskListService = nil
        saveCallCount = nil
        managedContext = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }

    func testMoveFromBacklogToTodayAppendsToEnd() throws {
        let todayFirst = makeTask(name: "Today 1", listId: .Today, position: 1)
        let todaySecond = makeTask(name: "Today 2", listId: .Today, position: 2)
        let backlogTask = makeTask(name: "Backlog", listId: .Backlog, position: 1)
        try managedContext.save()

        try taskListService.move(backlogTask, from: .Backlog)

        XCTAssertEqual(backlogTask.taskListId, TaskListIds.Today.rawValue)
        XCTAssertEqual(backlogTask.position, 3)
        XCTAssertEqual(todayFirst.position, 1)
        XCTAssertEqual(todaySecond.position, 2)
        XCTAssertEqual(saveCallCount, 1)
    }

    func testMoveFromTodayToBacklogInsertsAtTopAndShiftsExistingBacklogTasks() throws {
        let movingTask = makeTask(name: "Today", listId: .Today, position: 1)
        let backlogFirst = makeTask(name: "Backlog 1", listId: .Backlog, position: 1)
        let backlogSecond = makeTask(name: "Backlog 2", listId: .Backlog, position: 2)
        try managedContext.save()

        try taskListService.move(movingTask, from: .Today)

        XCTAssertEqual(movingTask.taskListId, TaskListIds.Backlog.rawValue)
        XCTAssertEqual(movingTask.position, 1)
        XCTAssertEqual(backlogFirst.position, 2)
        XCTAssertEqual(backlogSecond.position, 3)
        XCTAssertEqual(saveCallCount, 1)
    }

    func testCreateTaskInTodayAppendsToEnd() throws {
        _ = makeTask(name: "Today 1", listId: .Today, position: 1)
        _ = makeTask(name: "Today 2", listId: .Today, position: 2)
        try managedContext.save()

        let viewController = TaskAddViewController()
        viewController.appContext = TestAppContext(managedContext: managedContext)
        viewController.newTaskTaskListId = .Today
        viewController.nameField.text = "New Today"

        XCTAssertTrue(viewController.createTask())

        let todayTasks = managedContext.getVisibleTasks(in: .Today).compactMap { $0 as? Task }
        let newTask = try XCTUnwrap(todayTasks.last)
        XCTAssertEqual(todayTasks.count, 3)
        XCTAssertEqual(newTask.name, "New Today")
        XCTAssertEqual(newTask.position, 3)
    }

    func testCreateTaskInBacklogInsertsAtTopAndShiftsExistingTasks() throws {
        let backlogFirst = makeTask(name: "Backlog 1", listId: .Backlog, position: 1)
        let backlogSecond = makeTask(name: "Backlog 2", listId: .Backlog, position: 2)
        try managedContext.save()

        let viewController = TaskAddViewController()
        viewController.appContext = TestAppContext(managedContext: managedContext)
        viewController.newTaskTaskListId = .Backlog
        viewController.nameField.text = "New Backlog"

        XCTAssertTrue(viewController.createTask())

        let backlogTasks = managedContext.getVisibleTasks(in: .Backlog).compactMap { $0 as? Task }
        let newTask = try XCTUnwrap(backlogTasks.first)
        XCTAssertEqual(backlogTasks.count, 3)
        XCTAssertEqual(newTask.name, "New Backlog")
        XCTAssertEqual(newTask.position, 1)
        XCTAssertEqual(backlogFirst.position, 2)
        XCTAssertEqual(backlogSecond.position, 3)
    }

    func testSmartSortGroupsCompletedThenFlaggedThenUnflaggedWhileKeepingRelativeOrder() throws {
        let flaggedFirst = makeTask(name: "Flagged 1", listId: .Today, position: 1, flagged: true)
        let unflaggedFirst = makeTask(name: "Unflagged 1", listId: .Today, position: 2)
        let completedFirst = makeTask(name: "Completed 1", listId: .Today, position: 3, completed: true)
        let flaggedSecond = makeTask(name: "Flagged 2", listId: .Today, position: 4, flagged: true)
        let completedSecond = makeTask(name: "Completed 2", listId: .Today, position: 5, completed: true)
        let unflaggedSecond = makeTask(name: "Unflagged 2", listId: .Today, position: 6)
        try managedContext.save()

        try taskListService.smartSort([
            flaggedFirst,
            unflaggedFirst,
            completedFirst,
            flaggedSecond,
            completedSecond,
            unflaggedSecond,
        ])

        XCTAssertEqual(completedFirst.position, 1)
        XCTAssertEqual(completedSecond.position, 2)
        XCTAssertEqual(flaggedFirst.position, 3)
        XCTAssertEqual(flaggedSecond.position, 4)
        XCTAssertEqual(unflaggedFirst.position, 5)
        XCTAssertEqual(unflaggedSecond.position, 6)
        XCTAssertEqual(saveCallCount, 1)
    }

    func testRemoveCompletedSoftDeletesOnlyCompletedVisibleTasksInSelectedList() throws {
        let todayCompleted = makeTask(name: "Today done", listId: .Today, position: 1, completed: true)
        let todayOutstanding = makeTask(name: "Today open", listId: .Today, position: 2)
        let todayRemoved = makeTask(name: "Today removed", listId: .Today, position: 3, completed: true, removed: true)
        let backlogCompleted = makeTask(name: "Backlog done", listId: .Backlog, position: 1, completed: true)
        try managedContext.save()

        try taskListService.removeCompleted(in: .Today)

        XCTAssertTrue(todayCompleted.removed)
        XCTAssertNotNil(todayCompleted.removedDate)
        XCTAssertFalse(todayOutstanding.removed)
        XCTAssertTrue(todayRemoved.removed)
        XCTAssertFalse(backlogCompleted.removed)
        XCTAssertEqual(saveCallCount, 1)
    }

    private func makeInMemoryPersistentContainer() throws -> NSPersistentContainer {
        guard let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: AppDelegate.self)]) else {
            throw NSError(domain: "GottaDoTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to load managed object model."])
        }

        let container = NSPersistentContainer(name: "GottaDo", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError {
            throw loadError
        }

        return container
    }

    @discardableResult
    private func makeTask(
        name: String,
        listId: TaskListIds,
        position: Int16,
        flagged: Bool = false,
        completed: Bool = false,
        removed: Bool = false
    ) -> Task {
        let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: managedContext) as! Task
        task.name = name
        task.taskListId = listId.rawValue
        task.position = position
        task.flagged = flagged
        task.completed = completed
        task.removed = removed
        task.createdDate = Date()
        task.completedDate = completed ? Date() : nil
        task.removedDate = removed ? Date() : nil
        return task
    }
}

private final class TestAppContext: AppContext {
    let managedContext: NSManagedObjectContext

    init(managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext
    }

    func saveContext() throws {
        if managedContext.hasChanges {
            try managedContext.save()
        }
    }

    func setBadgeNumber(_ number: Int) {}
}
