import CoreData

extension NSManagedObjectContext {
    
    func getVisibleTasks(in taskListId: TaskListIds) -> Array<NSManagedObject> {
        var tasks: [NSManagedObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND removed != %@", NSNumber(value: taskListId.rawValue), NSNumber(value: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        
        do {
            tasks = try self.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return tasks
    }
    
    func getCompletedVisibleTasks(in taskListId: TaskListIds) -> Array<NSManagedObject> {
        var tasks: [NSManagedObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "taskListId = %@ AND completed == %@ AND removed != %@", NSNumber(value: taskListId.rawValue), NSNumber(value: true), NSNumber(value: true))
        
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
            return try self.count(for: fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return 0
        }
    }
    
}
