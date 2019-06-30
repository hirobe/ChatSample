#  RxSwift（とFirebase）でチャットツールを書く

RxSwiftの勉強のために、Firebaseを使ったシンプルなチャットツールのコードを書いてみました。

- Xcode: 10.2.1 ( iOS12 )
- RxSwift: 5.0.0

ライブラリ管理にはCocoaPodsを使っています。

# 画面構成と機能

サインアップ、サインイン、チャットの3画面という必要最低限の画面で構成されます。
チャネルやルームの選択も、参加者の招待もできない超省略仕様です。

![Image1.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/1209/c20ea5d9-a779-117e-2f38-197464c21c3c.png)

チャット画面では、画面の下にテキスト入力フィールドを表示します。
送信ボタンを押すと書いたものがリストに追加されるという、よくあるやつです。
リストには、ユーザ名と投稿したメッセージを表示します。

# ソースコードと実行方法
コードは、 https://github.com/hirobe/ChatSample にあります。
実行するには、Firebaseにプロジェクトを作成する必要があります。

## Firebaseプロジェクトの作成

Firebaseのコンソールへ移動し、プロジェクトを作成してください。
プロジェクトを作成したら、プロジェクトにiOSアプリを追加して、GoogleService-Info.plistダウンロードしてください。
XcodeでRxSwiftChatSampleを開いて、GoogleService-Info.plistをツリーにドロップしてプロジェクトに含めてください。

## Firebaseプロジェクトの設定

以下を使用します。
- Firebase Authentication
- Firebase Firestore

認証のためにFirebase Authenticationを使用します。Firebaseのコンソールへ移動し、Firebase Authenticationを追加してください。ログインプロバイダとしてメール/パスワードを有効にしてください。
メールリンクは使用しませんのでOFFにしてください。

### Firestore設定

DBとしてFirestoreを利用します。Firebaseのコンソールへ移動し、Databaseを追加してCloud FireStoreを選んでください(Realtime Databaseではありません)。
"＋コレクションを追加"をクリックして"messages"というコレクションを作成してください。この下に投稿したメッセージが作られます。

続けて、ルールタブを選んで、右ペインに以下を貼り付けてください。認証済みユーザはで全データの読み書きができる設定です（あくまで開発用。本番用はちゃんと検討すべき）

```
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

以上で、サーバの準備は完了です。Firebaseは簡単ですねぇ

# コードの説明

サインアップと、チャットの2画面を書きます。
サインイン画面はFirebaseがFirebaseUIという形で提供しているものを使用します。

- MessageViewController : チャット画面
- SignUpViewController : サインアップ

## サインアップ

サインアップ画面は、Email, username, password, password confirmの4項目の入力フィールドとサインアップボタンを持ちます。ユーザが、4項目入力してサインアップボタンを押したらFirebaseにユーザを作成します。また、サインイン画面へ遷移するLoginボタンを持ちます。
![SignUp.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/1209/6d4b1f70-0cef-ae92-3998-bbab36db8384.png)

以下のファイルからなります。

- SignUp
    - Model
        - SignUpValidator.swift
        - SignUpDefaultAPI.swift
    - ViewModel
        - SignUpViewModel.swift
    - View
        - SignUp.storyboard
        - SignUpViewController.Swift

(実際のソースコードは https://github.com/hirobe/ChatSample/tree/master/RxSwiftChatSample を参照)


サインアップ画面はRxSwiftが提供しているサンプルコードRxExample( https://github.com/ReactiveX/RxSwift/tree/master/RxExample )のGitHubSignupのusingDriverを参考にしており、流れは同じです。

### Model

Model層はFirebaseのAPIを呼ぶSignUpDefaultAPI, 入力値の検査を行うSignUpValidatorです。
SinUpDefaultAPI.swiftでは、Firebase Authenticationにユーザを作り、入力されたUsernameをdisplayNameとしてセットして、結果をObservableとして返します。ちなみに、ここではシンプルにFirebae Authenticationだけにユーザを作成していますが、本来ならFirestoreにもパスワード等を除いたユーザ情報をドキュメントとして保存するのが良いでしょうね。Firebase Authenticationの他のユーザのデータはアプリで参照できないので。

### ViewModel

ViewのTextFieldをDriverとして受け取り、入力値のValidationを生成します。
実際のValidationはモデル層のSignUpValidatorで行います。文字数とかPasswordとかPassword confirmが同一かどうかを監視し、警告メッセージを出力します。
すべての入力がOKであればsignUpEnabledをtrueにします。
加えて、signUpTapsによりSignUpボタン押下時のAPI呼び出しを行います。

エラーの処理のために、signUpErrorというDriverを公開します。これはAPIの呼び出し結果をmaterialize()を使って、Errorを扱うためのストリームを分けています。errorの専用のストリームを用意することで、Viewではalertの表示がシンプルに行えます。（参照：RxSwift研究読本2）

また、API呼び出し中にグルグル回るインジケータを表示できるようにsigningUpというDirverを作成しています。このような処理中の制御には、RxExampleで使われているActivityIndicatorクラスが良さそうです。そのまま使っています。ActivityIndicatorは、監視対象がSubscribeされてからDisposeされるまでtrueとなるObservableです。これを監視してインジケータをまわします。インジケータにはかっこよかったのでJGProgressHUDを使用しています。

### View
SignUpViewControllerは4つの入力フィールドを持ちます。email,username,password,password confirmです。ViweModelにこれらのDriverを渡すとともに、ViewModelからの出力を監視し警告メッセージ、ボタンの有効、エラーメッセージの表示を行います。
また、ログインのボタンを押された場合は、サインイン画面を生成し遷移します。サインイン画面はFirebaseUIが提供するものを使っていますので、サインイン画面に関するソースコードはありません。

ところで、実はFirebaseUIはサインインだけじゃなくサインアップも可能なのですが、ここではFUIEmailAuthのallowNewEmailAccountsプロパティをfalseにすることで、サインアップをできなくしています。

## チャット

チャットの画面の機能は、大きく以下の2つになります。
1. 画面下部の入力フィールドに入力されたメッセージをサーバーにPOSTする機能
2. チャットのメッセージをサーバから取得してTableViewに表示する機能

![Chat.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/1209/08f01076-e958-7098-7520-6dd5a985a9e8.png)

### 入力とPOSTの機能

入力フィールド(InptToolbarView)の制御およびPOSTは以下のファイルが担当します。

- Message
  - Model
    - PostDefaultAPI.swift
  - ViewModel
    - InputToolbarViewModel.swift
  - View
    - InputToolbar.xib
    - InputToolbarView.swift

InputToolbarView自体は、チャット画面であるMessageViewControllerのInputAccessaryViewプロパティに指定することで、画面の下部に表示します。最初は画面下に表示しつつキーボードが表示されたらそれに合わせてキーボードの上部に移動するのは、妙に難しいコツがいるのですが、概ね以下のやり方で実現できます。詳しくはMessageViewControllerとInpuToolbarViewのソースを見てください。

- MessageViewControllerのcanBecomeFirstResponderプロパティでtrueを返す
- MessageViewControllerのinputAccessoryViewプロパティでInputToolbarViewを返す
- InputToolbarViewではlayoutMarginsGuideに対してAutolayout constraintを設定する

また、些細なUI改善として、キーボードのEnterを押してもキーボードが隠れないようしています。UITextFieldDelegateのtextFieldShouldReturnでfalseを返すとキーボードが隠れません。

POSTの処理はPostDefaultAPIで行います。中でFirestoreにレコードを作っています。エラー処理はサインアップと同様にError用のDriverを生成して、Viewでそれを受けてアラートを表示します。

### メッセージをサーバから取得してTableViewに表示する機能

メッセージの表示に関わる処理は以下のファイルになります。
サーバからのデータの取得には、Firestoreのスナップショットリスナーを使用します。これはリスナーを作成しておけば、サーバと勝手にデータを同期してくれる便利なやつです。addSnapshotListenerのlistenerブロック内でonNextを発行すれば、サーバのデータを勝手に監視しつつデータを同期してくれるObserverの出来上がりです(MessageListener.swift)。

ViewModelでやっていることは、MessageLisnterのObserverを公開しているだけです。addSnapshotListenerの変更通知は一度に複数回起きることがあるので、debounce()でまとめています。

ViewではviewModel.items.driveをtableView.rx.itemにdriveして(bindして)います。ソースを見ると、サーバからデータを取得してtableViewに表示するまで行数にして100stepたらずで実現できていることがわかると思います。RxSwiftとFirebaseの力は恐るべしですねー

MessageViewControllerでは、そのほかにInputToolbarViewの表示、RxKeyboard( https://github.com/RxSwiftCommunity/RxKeyboard )を使用したキーボード表示時のスクロール制御、上スクロールによる入力のキャンセル、メッセージ追加時のスクロールを行っています。

- Message
  - Model
    - Message.swift
    - MessageLisitener.swift
  - ViewModel
    - MessageViewModel.swift
  - View
    - Message.storyboard
    - MessageCell.swift
    - MessageViewController.swift

# 参考文献

参考にした資料です。

- RxEample https://github.com/ReactiveX/RxSwift/tree/master/RxExample
-　RxSwift研究読本1〜3 https://swift.booth.pm/
- 
RxSwift で多重実行防止と実行中の表現を簡潔に書く https://blog.cybozu.io/entry/2018/12/27/080000
- 【Swift】inputAccessoryViewがiPhoneXのホームボタンエリアに被る件を解決する(コードでViewを書いた場合) https://qiita.com/shiz/items/0dd53237fe85473b925f
-  mono0926/1Database.swift https://gist.github.com/mono0926/ae6c491862370348ad4b4fcc7b4a5556

## 終わりに

RxSwift初心者なので変な書き方があれば指摘していただければ。

WWDCでSwiftUIも発表されたので、この後同じものをSwiftUIでも書いてみようと思います。
