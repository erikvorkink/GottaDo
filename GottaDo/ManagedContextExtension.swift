import CoreData

extension NSManagedObjectContext {
    
    func getTasks(in taskListId: TaskListIds) -> Array<NSManagedObject> {
        var tasks: [NSManagedObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND removed != %@", NSNumber(value: taskListId.rawValue), NSNumber(value: true))
        
        do {
            tasks = try self.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return tasks
    }
    
    func getOutstandingTaskCount(in taskListId: TaskListIds) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed != %@", NSNumber(value: taskListId.rawValue), NSNumber(value: true))
        
        do {
            let count = try self.count(for: fetchRequest)
            return count
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return 0
        }
    }
}
