import Foundation
import UIKit

class TodoItemCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.textLabel?.numberOfLines = 0
        self.textLabel?.font = UIFont.systemFont(ofSize: 20)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding is not supported")
    }
}
