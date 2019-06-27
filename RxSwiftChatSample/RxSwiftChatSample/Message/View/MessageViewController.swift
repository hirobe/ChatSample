import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD
import RxKeyboard

class MessageViewController: UIViewController, UITableViewDelegate, ProgressHudEnable, ErrorAlertEnable {

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var closeButton: UIBarButtonItem!

    var inputToolbarView: InputToolbarView!

    let progressHud = JGProgressHUD(style: .dark)

    var disposeBag = DisposeBag()
    
    var viewModel:MessageViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = MessageViewModel(
            messageListener: MessageDefaultListener()
        )

        // セルにデータを割り当てる
        viewModel.items
            .drive( tableView.rx.items(cellIdentifier: "MessageCell", cellType: MessageCell.self)) { _, element, cell in
                cell.configure(message: element)
            }
            .disposed(by: disposeBag)

        // メッセージが変化したら最下部にスクロールする
        viewModel.items
            .drive(onNext: { [weak self] messages in
                self?.scrollToBottom(tableView: self?.tableView)
            })
            .disposed(by: disposeBag)

        // 画面下部の入力エリアの設定
        inputToolbarView = InputToolbarView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))

        // POST失敗時はアラートを表示する
        inputToolbarView.viewModel.postError
            .drive( self.rx.showErrorAlert )
            .disposed(by: disposeBag)

        // keyboardの表示に合わせてtableViewをスクロール
        RxKeyboard.instance.visibleHeight
            .debounce(.milliseconds(300))
            .drive(onNext: { [tableView] keyboardVisibleHeight in
                tableView?.contentInset.bottom = keyboardVisibleHeight
                self.scrollToBottom(tableView: tableView)
            })
            .disposed(by: disposeBag)

        // 上スクロールしたらキーボードを隠す
        tableView.panGestureRecognizer.rx.event
            .filter { $0.velocity(in: self.tableView).y > 100 }
            .subscribe(onNext: { [weak self] _ in
                _ = self?.inputToolbarView.endEditing(true)
            })
            .disposed(by: disposeBag)

    }
    
    private func scrollToBottom(tableView:UITableView?) {
        guard let tableView = tableView,
        let rowCount = tableView.dataSource?.tableView(tableView, numberOfRowsInSection: 0),
            rowCount > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: rowCount - 1, section: 0), at: .bottom, animated: true)
    }

    override var canBecomeFirstResponder: Bool {
        // 画面下部にinputAccessoryViewを表示する
        return true
    }

    override var inputAccessoryView: UIView {
        return self.inputToolbarView
    }

    @IBAction private func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
