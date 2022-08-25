//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

//public final class ErrorView: UIView {
//
//    private lazy var messageLabel = UILabel()
//
//    public var message: String? {
//        get { messageLabel.text }
//        set {
//            if let message = newValue {
//                messageLabel.text = message
//                isHidden = false
//            } else {
//                isHidden = true
//            }
//        }
//    }
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        isHidden = true
//
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.contentMode = .scaleToFill
//
//        addSubview(stack)
//
//        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        stack.topAnchor.constraint(equalTo: topAnchor).isActive = true
//        stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
//        stack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//        stack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
//
//        heightAnchor.constraint(greaterThanOrEqualTo: stack.heightAnchor, multiplier: 0).isActive = true
//        widthAnchor.constraint(greaterThanOrEqualTo: stack.widthAnchor, multiplier: 0).isActive = true
//
//        let image = UIImage(systemName: "trash")
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//
//        stack.addArrangedSubview(imageView)
//
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
//        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//
//        stack.addArrangedSubview(messageLabel)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}

public final class IssuesViewController: UIViewController, IssuesView, UITableViewDataSource {
    var loadIssues: (() -> Void)?
    
    public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
        
    public private(set) lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
        
    private var issues = [IssueViewModel]() {
        didSet { tableView.reloadData() }
    }

    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UINib(nibName: "IssueCell", bundle: .main), forCellReuseIdentifier: "IssueCell")
        tableView.dataSource = self
        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(errorLabel)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        loadIssues?()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        issues.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IssueCell") as! IssueCell
        cell.nameLabel.text = issues[indexPath.row].name
        cell.issueCountLabel.text = issues[indexPath.row].amountOfIssues
        cell.birthDateLabel.text = issues[indexPath.row].birthDate
        return cell
    }
    
    public func present(issues: [IssueViewModel]) {
        self.issues = issues
    }
    
    public func presentLoading(_ isLoading: Bool) {
        isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    public func presentError(_ message: String?) {
        errorLabel.text = message
        errorLabel.isHidden = message == nil
    }
}
