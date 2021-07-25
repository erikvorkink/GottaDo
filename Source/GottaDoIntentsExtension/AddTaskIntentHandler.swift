import Foundation
import Intents

class AddTaskIntentHandler : NSObject, AddTaskIntentHandling {
    func handle(intent: AddTaskIntent, completion: @escaping (AddTaskIntentResponse) -> Void) {
        print("task to add: ", intent.task!)
        // TODO: communicate with the main app to add intent.task
        completion(AddTaskIntentResponse.success(result: "successfully"))
    }
    
    func resolveTask(for intent: AddTaskIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if intent.task == "(task)" {
            completion(INStringResolutionResult.needsValue())
        } else {
            completion(INStringResolutionResult.success(with: intent.task!))
        }
    }
    
}
