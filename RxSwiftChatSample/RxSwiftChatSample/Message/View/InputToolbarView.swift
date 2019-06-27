import UIKit
import RxSwift
import RxCocoa

/**
 画面下部に表示するメッセージ入力用のテキストフィールド
 behaviour:
 - Sendボタン押下、またはキーボードでEnter入力時にAPIへPOSTする
 - テキストフィールドが空の時はSendボタンをdisableにしつつenterでもpostしない
 - POST中はSendボタンをdisableに
 */
class InputToolbarView: UIView, UITextFieldDelegate {

    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var sendButton: UIButton!

    var viewModel: InputToolbarViewModel!
    var disposeBag = DisposeBag()

    var returnKeyPress: PublishSubject<()>!

    override init(frame: CGRect) {
        super.init(frame: frame)
        _ = loadNib("InputToolbar")
        self.backgroundColor = UIColor.yellow

        returnKeyPress = PublishSubject<()>()

        viewModel = InputToolbarViewModel(
            input: (textField.rx.text.orEmpty.asDriver(),
                    sendButton.rx.tap.asSignal(),
                    returnKeyPress.asSignal(onErrorJustReturn: ())
            ),
            postAPI: PostDefaultAPI())

        // Sendボタンの有効条件
        Driver.combineLatest(viewModel.postEnabled, viewModel.posting)
            .drive(onNext: { [weak self] postEnabled, posting in
                self?.sendButton.isEnabled = postEnabled && !posting
            })
            .disposed(by: disposeBag)

        // postが完了したらフィールドをクリア
        viewModel.posted
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] _  in
                self?.textField.text = ""
                self?.textField.sendActions(for: .valueChanged)
            })
            .disposed(by: disposeBag)

        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // RETURNキーでキーボードを隠さないためのHack
        // shoudReturnでfalseを返しつつ、代わりのイベントを発行する

        returnKeyPress.onNext(())

        return false
    }

    override func endEditing(_ force: Bool) -> Bool {
        // キーボードを隠す
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
        return true
    }

}

/// ビューのレイアウトに関するextension
extension InputToolbarView {

    // xibからカスタムViewを読み込んで準備する
    func loadNib(_ nibName: String) -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError("cant load nib") }

        self.addSubview(view)

        // うまくinputAccessoryViewに収まるようにconstraintをつける
        self.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor, constant: 4).isActive = true
        view.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor, constant: -4).isActive = true
        view.leftAnchor.constraint(equalTo: self.layoutMarginsGuide.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: self.layoutMarginsGuide.rightAnchor).isActive = true

        return view
    }

    override var intrinsicContentSize: CGSize {
        // うまくinputAccessoryViewに収まるように
        return CGSize.zero
    }
}
