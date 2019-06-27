import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

import FirebaseUI

class SignUpViewController: UIViewController, ProgressHudEnable, ErrorAlertEnable {

    @IBOutlet private weak var emailOutlet: UITextField!
    @IBOutlet private weak var emailValidOutlet: UILabel!

    @IBOutlet private weak var usernameOutlet: UITextField!
    @IBOutlet private weak var usernameValidOutlet: UILabel!

    @IBOutlet private weak var passwordOutlet: UITextField!
    @IBOutlet private weak var passwordValidOutlet: UILabel!
    @IBOutlet private weak var passwordConfirmOutlet: UITextField!
    @IBOutlet private weak var passwordConfirmValidOutlet: UILabel!

    @IBOutlet private weak var signUpButon: UIButton!
    @IBOutlet private weak var signInUIButton: UIButton!

    let progressHud = JGProgressHUD(style: .dark)

    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        signInUIButton.addTarget(self, action: #selector(signInUIButtonTapped(any:)), for: .touchUpInside)

        let viewModel = SignUpViewModel(
            input:
            (
                email: emailOutlet.rx.text.orEmpty.asDriver(),
                username: usernameOutlet.rx.text.orEmpty.asDriver(),
                password: passwordOutlet.rx.text.orEmpty.asDriver(),
                passwordConfirm: passwordConfirmOutlet.rx.text.orEmpty.asDriver(),
                signUpTaps: signUpButon.rx.tap.asSignal()
            ),
            signUpAPI: SignUpDefaultAPI()
        )

        viewModel.emailValidation
            .drive(emailValidOutlet.rx.validationResult)
            .disposed(by: disposeBag)

        viewModel.usernameValidation
            .drive(usernameValidOutlet.rx.validationResult)
            .disposed(by: disposeBag)

        viewModel.passwordValidation
            .drive(passwordValidOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.passwordConfirmValidation
            .drive(passwordConfirmValidOutlet.rx.validationResult)
            .disposed(by: disposeBag)

        viewModel.signUpEnabled
            .drive(onNext: { [weak self] valid  in
                self?.signUpButon.isEnabled = valid
                self?.signUpButon.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)

        viewModel.signedUp
            .drive(onNext: { _ in
                // サインアップに成功したら入力フィールドをクリア
                self.emailOutlet.text = ""
                self.emailOutlet.sendActions(for: .valueChanged)
                self.usernameOutlet.text = ""
                self.usernameOutlet.sendActions(for: .valueChanged)
                self.passwordOutlet.text = ""
                self.passwordOutlet.sendActions(for: .valueChanged)
                self.passwordConfirmOutlet.text = ""
                self.passwordConfirmOutlet.sendActions(for: .valueChanged)

                self.performSegue(withIdentifier: "OpenMessages", sender: self)
            })
            .disposed(by: disposeBag)

        viewModel.signingUp
            .drive( self.rx.showProgressHud)
            .disposed(by: disposeBag)

        // POST失敗時はアラートを表示する
        viewModel.signUpError
            .drive( self.rx.showErrorAlert )
            .disposed(by: disposeBag)

        // 背景をタップしたらキーボードを隠す
        let tapBackground = UITapGestureRecognizer()
        tapBackground.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapBackground)

    }
    
    /*
    // ログイン済みならMessageを表示
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _ = Auth.auth().currentUser {
            self.performSegue(withIdentifier: "OpenMessages", sender: self)
        }
    }
    */
}

/// ログインはFirebaseUIを利用する
extension SignUpViewController: FUIAuthDelegate {
    @objc func signInUIButtonTapped(any: UIControl) {
        guard let authUI = FUIAuth.defaultAuthUI() else { fatalError("FUIAuth i nil") }

        authUI.delegate = self
        let providers: [FUIAuthProvider] = [
            FUIEmailAuth(authAuthUI: authUI, signInMethod: EmailPasswordAuthSignInMethod, forceSameDevice: false, allowNewEmailAccounts: false, actionCodeSetting: ActionCodeSettings())
        ]
        authUI.providers = providers
        let authViewController = authUI.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }

    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if error == nil {
            self.performSegue(withIdentifier: "OpenMessages", sender: self)
        }
    }
}
