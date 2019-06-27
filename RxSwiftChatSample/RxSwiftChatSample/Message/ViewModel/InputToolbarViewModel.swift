import UIKit
import RxSwift
import RxCocoa

class InputToolbarViewModel: NSObject {

    let messageValidation: Driver<ValidationResult>
    let postEnabled: Driver<Bool>
    let posting: Driver<Bool>

    let posted: Driver<String>
    let postError: Driver<Error>

    init(input:(
        message: Driver<String>,
        sendTaps: Signal<()>,
        enterKeyTaps: Signal<()>
        ),
         postAPI: PostAPI
        ) {

        let messageValidator = MessageValidator()
        messageValidation = input.message
            .map { message in
                messageValidator.validateMessage(message)
            }

        let posting = ActivityIndicator()
        self.posting = posting.asDriver()

        let results = Signal.merge(input.sendTaps, input.enterKeyTaps)
            .asObservable()
            .withLatestFrom(input.message)
            .flatMapLatest {
                postAPI.post(message: $0)
                    .trackActivity(posting)
                    .materialize()
            }
            .share(replay: 1)

        posted = results
            .filter { $0.event.element?.documentID != nil }
            .map { $0.event.element?.documentID ?? "" }
            .asDriver(onErrorJustReturn: "" )

        postError = results
            .compactMap { $0.event.error }
            .asDriver(onErrorJustReturn: MyError.unknown )

        postEnabled = Driver.combineLatest(messageValidation, self.posting) { message, isPosting in
            message.isValid && !isPosting
        }
            .distinctUntilChanged()
    }
}
