import UIKit
import RealmSwift
import BWSwipeRevealCell

class TodoViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, BWSwipeRevealCellDelegate {

    // https://realm.io/docs/swift/latest/#getting-started
    
    // UI elements
    var textField: UITextField!
    var tableView: UITableView!
    
    // Realm
    let realm = try! Realm()
    let results = try! Realm().objects(Todo.self).sorted(byProperty: "createdAt", ascending: false)
    
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    func setupNotifications() {
        
        // Realm notifications
        self.notificationToken = results.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {

            case .initial:
                self.tableView.reloadData()
                break
                
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .right)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
                break
                
            case .error(let err):
                fatalError("Opsss: \(err)")
                break
                
            }
        }
        
    }
    
    func setupUI() {
        self.title = "Quick Do"
        self.view.backgroundColor = UIColor.white
        
        textField = UITextField()
        textField.returnKeyType = UIReturnKeyType.done
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = UIFont(name: "Metric-Regular", size: 20)
        textField.textColor = UIColor.black
        textField.setLeftPadding(10)
        textField.setRightPadding(8)
        self.view.addSubview(self.textField)
        
        // Add shadow to textfield
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.masksToBounds = false
        textField.layer.cornerRadius = 6.0
        textField.layer.shadowColor = UIColor(hexString: "#3498db").cgColor
        textField.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        textField.layer.shadowOpacity = 0.2
        textField.layer.shadowRadius = 3.0
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        self.view.addSubview(self.tableView)
        
        // Setup cell
        tableView.register(BWSwipeRevealCell.self, forCellReuseIdentifier: "TodoItemCellIdentifier")
        
        self.setupConstraints()
    }
    
    func setupConstraints() {
        // Make the constraints start below navigation bar
        if self.responds(to: NSSelectorFromString("edgesForExtendedLayout")) {
            edgesForExtendedLayout = []
        }
        
        let views = ["textField": self.textField, "tableView": self.tableView] as [String : Any]
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[textField]-10-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[textField(==50)]-5-[tableView]|", options: [], metrics: nil, views: views))
    }
    
    // MARK: - Create, update, delete
    
    func updateTodo(atIndexPath indexPath: IndexPath) {
        realm.beginWrite()
        
        let item = results[indexPath.row]
        item.done = !item.done
        
        try! realm.commitWrite()
    }
    
    func removeTodo(atIndexPath indexPath: IndexPath) {
        realm.beginWrite()
        realm.delete(results[indexPath.row])
        try! realm.commitWrite()
    }
    
    func createNewTodo(text: String) {
        print("Creating new todo with text: \(text)")
        
        realm.beginWrite()
        realm.create(Todo.self, value: ["text": text, "done": false], update: false)
        try! realm.commitWrite()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text != nil) {
            createNewTodo(text: textField.text!)
            textField.text = nil
            
            return true
        }
        
        return false
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCellIdentifier", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let swipeCell:BWSwipeRevealCell = cell as! BWSwipeRevealCell
        
        swipeCell.preservesSuperviewLayoutMargins = false
        swipeCell.separatorInset = UIEdgeInsets.zero
        swipeCell.layoutMargins = UIEdgeInsets.zero
        
        swipeCell.delegate = self
        swipeCell.type = .springRelease
        
        // Inactive color while swiping cell
        swipeCell.bgViewInactiveColor = UIColor(hexString: "#bdc3c7")
        
        swipeCell.bgViewLeftImage = UIImage(named: "checked")!.withRenderingMode(.alwaysTemplate)
        swipeCell.bgViewLeftColor = UIColor(hexString: "#27ae60")
        
        swipeCell.bgViewRightImage = UIImage(named: "delete")!.withRenderingMode(.alwaysTemplate)
        swipeCell.bgViewRightColor = UIColor(hexString: "#e74c3c")
        
        let item = results[indexPath.row]
        
        swipeCell.textLabel?.numberOfLines = 0
        swipeCell.textLabel?.font = UIFont(name: "Metric-Regular", size: 18)
        swipeCell.textLabel?.textColor = (item.done ? UIColor.lightGray : UIColor.black)
        swipeCell.textLabel?.text = (item.done ? "🎉 \(item.text)" : item.text)
    }
    
    // MARK: - Reveal Cell Delegate
    
    func swipeCellDidCompleteRelease(_ cell: BWSwipeCell) {
        print("Swipe Cell Did Complete: \(cell.state)")
        
        let indexPath: IndexPath = tableView.indexPath(for: cell)!
        
        // Will delete todo item
        if cell.state == .pastThresholdRight && cell.type != .slidingDoor {
            self.removeTodo(atIndexPath: indexPath)
        }
        
        // Will mark as done
        if (cell.state == .pastThresholdLeft && cell.type != .slidingDoor) {
            self.updateTodo(atIndexPath: indexPath)
        }
    }

}
