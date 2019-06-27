import UIKit
import RxCocoa
import RxSwift

protocol ErrorAlertEnable: UIViewController {
}

extension Reactive where Base: ErrorAlertEnable {
    var showErrorAlert: Binder<Error?> {
        return Binder(self.base) { target, value in
            if let error = value {
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)

                target.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
