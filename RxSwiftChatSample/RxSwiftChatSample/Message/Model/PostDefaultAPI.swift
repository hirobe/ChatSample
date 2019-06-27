import Foundation
import RxSwift
import Firebase

protocol PostAPI {
    func post(message: String) -> Observable<DocumentReference>
}

final class PostDefaultAPI: PostAPI {

    func post(message: String) -> Observable<DocumentReference> {
        return Observable<DocumentReference>.create { observer in
            guard let user = Auth.auth().currentUser else {
                observer.onError(MyError.notAuth)
                return Disposables.create()
            }
            let userId = user.uid
            let username = user.displayName ?? ""
            let date = Date()

            var ref: DocumentReference?

            let db = Firestore.firestore()
            let message = Message(userId: userId, username:username, message: message, createdAt: date, updatedAt: date)
            ref = db.collection("messages").addDocument(data: message.documentDictionary()) { error in
                if let error = error {
                    observer.onError(error)
                } else if let ref = ref {
                    observer.onNext(ref)
                    observer.onCompleted()
                } else {
                    observer.onError(MyError.unknown)
                }
            }
            return Disposables.create()
        }
    }

}
