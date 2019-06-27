import UIKit

class MessageCell: UITableViewCell {
    @IBOutlet private weak var messageLabel: UILabel!

    @IBOutlet weak var usernameLabel: UILabel!
    
    func configure(message: Message) {
        messageLabel.text = message.message
        usernameLabel.text = message.username
    }
}
