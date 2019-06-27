import RxSwift
import RxCocoa

enum MyError: Error {
    case notAuth
    case unknown
}

enum ValidationResult {
    case ok(message: String)
    case empty(message: String)
    case validating
    case failed(message: String)

    var description: String {
        switch self {
        case let .ok(message) : return message
        case let .empty(message) : return message
        case .validating : return ""
        case let .failed(message) : return message
        }
    }

    var isValid: Bool {
        switch self {
        case .ok:
            return true
        default:
            return false
        }
    }
}

extension Reactive where Base: UILabel {
    var validationResult: Binder<ValidationResult> {
        return Binder(base) { label, result in
            label.text = result.description
        }
    }
}
