import CoreData

extension NSManagedObjectContext {

    private func fetchTasks(_ fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        var tasks: [NSManagedObject] = []
        do {
            tasks = try fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return tasks
    }

    func getVisibleTasks(in taskListId: TaskListIds) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND removed = %@",
                                             NSNumber(value: taskListId.rawValue),
                                             NSNumber(value: false))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        return fetchTasks(fetchRequest)
    }

    func getCompletedVisibleTasks(in taskListId: TaskListIds) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed = %@ AND removed = %@",
                                             NSNumber(value: taskListId.rawValue),
                                             NSNumber(value: true),
                                             NSNumber(value: false))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        return fetchTasks(fetchRequest)
    }

    func getCompletedTasks() -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "completed = %@", NSNumber(value: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        return fetchTasks(fetchRequest)
    }

    func getOutstandingVisibleTasks(in taskListId: TaskListIds) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed = %@ AND removed = %@",
                                             NSNumber(value: taskListId.rawValue),
                                             NSNumber(value: false),
                                             NSNumber(value: false))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        return fetchTasks(fetchRequest)
    }

    func getOutstandingVisibleTaskCount(in taskListId: TaskListIds) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed = %@ AND removed = %@",
                                             NSNumber(value: taskListId.rawValue),
                                             NSNumber(value: false),
                                             NSNumber(value: false))

        do {
            return try count(for: fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return 0
        }
    }

    func getHighestVisibleTaskPosition(in taskListId: TaskListIds) -> Int {
        let tasks = getVisibleTasks(in: taskListId)
        return tasks.last?.value(forKey: "position") as? Int ?? 0
    }

    func deleteOldCompletedTasks() {
        let daysAgoConsideredOld = 90
        let mostRecentDateToDelete = Calendar.current.date(byAdding: .day, value: -daysAgoConsideredOld, to: Date())

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "completed = %@ AND completedDate <= %@",
                                             argumentArray: [NSNumber(value: true), mostRecentDateToDelete!])
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try execute(deleteRequest)
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }

    func deleteAllTasks() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try execute(deleteRequest)
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
}
