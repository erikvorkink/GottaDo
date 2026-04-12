import UIKit
import CoreData

protocol AppContext {
    var managedContext: NSManagedObjectContext { get }
    func saveContext() throws
    func setBadgeNumber(_ number: Int)
}

extension UIApplication {
    var appContext: AppContext? {
        return delegate as? AppContext
    }
}
