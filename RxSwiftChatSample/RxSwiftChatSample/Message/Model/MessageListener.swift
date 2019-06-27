import UIKit
import RxSwift
import RxCocoa
import Firebase

protocol MessageListener {
    var items: Observable<[Message]> { get }
}

class MessageDefaultListener: NSObject, MessageListener {
    lazy var items = { createListener() }()
    private var listener: ListenerRegistration?

    private func createListener() -> Observable<[Message]> {

        return Observable<[Message]>.create { observer in
            let db = Firestore.firestore()

            // get messages
            self.listener = db
                .collection("messages")
                .order(by: "createdAt")
                .addSnapshotListener { documentSnapshot, error in
                    guard let documentSnapshot = documentSnapshot else {
                        fatalError("documentSnapshot is nil")
                    }
                    if let error = error {
                        observer.onError(error)
                    } else {
                        let documents = documentSnapshot.documents.map {
                            Message.create(from: $0)
                        }
                        observer.onNext(documents)
                    }
                }
            return Disposables.create {
                self.listener?.remove()
            }
        }
    }
}
