import Foundation

extension Task {
    func complete() {
        self.setValue(true, forKey: "completed")
        self.setValue(Date(), forKey: "completedDate")
    }
    
    func uncomplete() {
        self.setValue(false, forKey: "completed")
        self.setValue(nil, forKey: "completedDate")
    }
    
    func remove() {
        self.setValue(true, forKey: "removed")
        self.setValue(Date(), forKey: "removedDate")
    }
    
    func setName(_ name: NSString) {
        self.setValue(name, forKey: "name")
    }
    
    func setTaskListId(_ taskListId: TaskListIds) {
        self.setValue(taskListId.rawValue, forKey: "taskListId")
    }
    
    func setFlagged(_ flagged: Bool) {
         self.setValue(flagged, forKey: "flagged")
    }
    
    func toggleFlagged() {
        self.setFlagged(!self.flagged)
    }
}
