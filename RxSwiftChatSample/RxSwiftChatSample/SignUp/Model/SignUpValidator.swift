import Foundation
import RxSwift

class SignUpValidator {
    let minPasswordCount = 6
    let minUsernameCount = 3

    func validateEmail(_ email: String) -> ValidationResult {
        let numberOfCharacters = email.count
        if numberOfCharacters == 0 {
            return .empty(message: "")
        }
        if !email.contains("@") {
            return .failed(message: "Invalid email format")
        }
        return .ok(message: "")
    }

    func validateUsername(_ username: String) -> ValidationResult {
        let numberOfCharacters = username.count
        if numberOfCharacters == 0 {
            return .empty(message: "")
        }
        if numberOfCharacters < minUsernameCount {
            return .failed(message: "Email must be at least \(minUsernameCount) characters")
        }
        return .ok(message: "")
    }

    func validatePassword(_ password: String) -> ValidationResult {
        let numberOfCharacters = password.count
        if numberOfCharacters == 0 {
            return .empty(message: "")
        }
        if numberOfCharacters < minPasswordCount {
            return .failed(message: "Password must be at least \(minPasswordCount) characters")
        }
        return .ok(message: "")
    }
    
    func validatePasswordConfirm(_ password: String, _ passwordConfirm: String) -> ValidationResult {
        if password != passwordConfirm {
            return .failed(message: "Password and confirm are differ")
        }
        return .ok(message: "")
    }

}
