import Foundation
import RxSwift
import Firebase
import FirebaseAuth

protocol SignUpAPI {
    func signUp(email: String, password: String, username: String) -> Observable<User>
}

final class SignUpDefaultAPI: SignUpAPI {

    func signUp(email: String, password: String, username: String) -> Observable<User> {
        return Observable<User>.create { observer in
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let user = authResult?.user {
                    // usernameをuserに保存する
                    let req = user.createProfileChangeRequest()
                    req.displayName = username
                    req.commitChanges(completion: { (error) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(user)
                            observer.onCompleted()
                        }
                    })
                } else if let error = error {
                    observer.onError(error)
                } else {
                    observer.onError(MyError.unknown)
                }
            }
            return Disposables.create()
        }
    }
}
