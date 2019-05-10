import Foundation

extension Task {
    func setNewRecordValues(taskListId: TaskListIds, position: Int, name: String) {
        self.setTaskListId(taskListId)
        self.setPosition(position)
        self.setName(name)
        self.setValue(Date(), forKey: "createdDate")
        self.setValue(false, forKey: "completed")
        self.setValue(false, forKey: "removed")
    }
    
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
    
    func setName(_ name: String) {
        self.setValue(name, forKey: "name")
    }
    
    func setTaskListId(_ taskListId: TaskListIds) {
        self.setValue(taskListId.rawValue, forKey: "taskListId")
    }
    
    func setPosition(_ position: Int) {
        self.setValue(position, forKey: "position")
    }
    
    func setFlagged(_ flagged: Bool) {
         self.setValue(flagged, forKey: "flagged")
    }
    
    func toggleFlagged() {
        self.setFlagged(!self.flagged)
    }
}
