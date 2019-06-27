import UIKit
import RxSwift
import RxCocoa
import Firebase

class MessageViewModel: NSObject {

    let items: Driver<[Message]>
    
    init(messageListener: MessageListener) {
        items = messageListener.items
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance) // 複数回発生するので1回にまとめる
            .asDriver(onErrorJustReturn: [])
    }
}
