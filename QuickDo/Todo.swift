import Foundation
import RealmSwift

class Todo: Object {
    
    dynamic var text = ""
    dynamic var done = false
    dynamic var createdAt = NSDate()
}
