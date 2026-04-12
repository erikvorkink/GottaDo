import Foundation

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreatedByModal")
    static let taskEdited = Notification.Name("taskEditedByModal")
    static let taskDeleted = Notification.Name("taskDeletedByModal")
    static let bulkTasksDeleted = Notification.Name("bulkTasksDeleted")
}
