import Foundation
import RxSwift
import Firebase

struct Message {
    var userId: String
    var username: String
    var message: String
    var createdAt: Date
    var updatedAt: Date

    func documentDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "username": username,
            "message": message,
            "createdAt": Date(),
            "updatedAt": Date()
        ]
    }

    static func create(from: QueryDocumentSnapshot) -> Message {
        let data = from.data()
        return Message(userId: data["userId"] as? String ?? "",
                       username: data["username"] as? String ?? "",
                       message: data["message"] as? String ?? "",
                       createdAt: data["createdAt"] as? Date ?? Date(timeIntervalSince1970: 0),
                       updatedAt: data["createdAt"] as? Date ?? Date(timeIntervalSince1970: 0))
    }
}

class MessageValidator {
    func validateMessage(_ message: String) -> ValidationResult {
        if message.isEmpty {
            return .empty(message: "")
        }
        return .ok(message: "Message acceptable")
    }
}
