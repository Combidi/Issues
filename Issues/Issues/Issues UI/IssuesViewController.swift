//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public final class IssuesViewController: UIViewController, IssuesView, UITableViewDataSource {
    var loadIssues: (() -> Void)?
    
    public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
        
    public private(set) lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
        
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
    
    private var issues = [IssueViewModel]() {
        didSet { tableView.reloadData() }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        issues.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IssueCell") as! IssueCell
        let issue = issues[indexPath.row]
        cell.nameLabel.text = issue.name
        cell.issueCountLabel.text = issue.amountOfIssues
        cell.birthDateLabel.text = issue.birthDate
        return cell
    }
    
    public func present(issues: [IssueViewModel]) {
        self.issues = issues
    }
    
    public func presentLoading(_ isLoading: Bool) {
        isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    public func presentMessage(_ message: String?) {
        errorLabel.text = message
        errorLabel.isHidden = message == nil
    }
}
