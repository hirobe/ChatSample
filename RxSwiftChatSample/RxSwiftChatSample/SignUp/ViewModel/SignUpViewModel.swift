import RxSwift
import RxCocoa

class SignUpViewModel {

    let emailValidation: Driver<ValidationResult>
    let usernameValidation: Driver<ValidationResult>
    let passwordValidation: Driver<ValidationResult>
    let passwordConfirmValidation: Driver<ValidationResult>

    let signUpEnabled: Driver<Bool>
    let signedUp: Driver<Bool>
    let signingUp: Driver<Bool>
    let signUpError: Driver<Error>

    init(input:(
        email: Driver<String>,
        username: Driver<String>,
        password: Driver<String>,
        passwordConfirm: Driver<String>,
        signUpTaps: Signal<()>
        ),
         signUpAPI: SignUpAPI
        ) {
        
        let signinValidator = SignUpValidator()

        emailValidation = input.email
            .map { email in
                signinValidator.validateEmail(email)
        }
        
        usernameValidation = input.username
            .map { username in
                signinValidator.validateUsername(username)
            }

        passwordValidation = input.password
            .map { password in
                signinValidator.validatePassword(password)
            }

        passwordConfirmValidation = Driver.combineLatest(input.password, input.passwordConfirm)
            .map { password, passwordConfirm in
                signinValidator.validatePasswordConfirm(password, passwordConfirm)
        }

        let emailAndPassword = Driver.combineLatest(input.email, input.password, input.username) { (email: $0, password: $1, username:$2) }

        let signingIn = ActivityIndicator()
        self.signingUp = signingIn.asDriver()

        let results = input.signUpTaps
            .asObservable()
            .withLatestFrom(emailAndPassword)
            .flatMapLatest { tuple in
                signUpAPI.signUp(email: tuple.email, password: tuple.password, username: tuple.username)
                    .trackActivity(signingIn)
                    .materialize()
            }
            .share(replay: 1)

        signedUp = results
            .filter { $0.event.element != nil }
            .map { _ in true }
            .asDriver(onErrorJustReturn: false )

        signUpError = results
            .compactMap { $0.event.error }
            .asDriver(onErrorJustReturn: MyError.unknown )

        signUpEnabled = Driver.combineLatest(
            emailValidation,
            usernameValidation,
            passwordValidation,
            passwordConfirmValidation,
            signingUp
        ) { email, username, password, passwordConfirm, signingUp in
            email.isValid && username.isValid &&
                password.isValid && passwordConfirm.isValid && !signingUp
        }
            .distinctUntilChanged()

    }
}
