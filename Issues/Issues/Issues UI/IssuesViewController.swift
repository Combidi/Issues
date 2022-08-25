//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public final class IssuesViewController: UIViewController, IssuesView, UITableViewDataSource {
    var loadIssues: (() -> Void)?
    
    public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
        
    public private(set) var errorLabel = UILabel()
        
    private var issues = [IssueViewModel]() {
        didSet { tableView.reloadData() }
    }

    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.register(UINib(nibName: "IssueCell", bundle: .main), forCellReuseIdentifier: "IssueCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
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
        activityIndicator.stopAnimating()
    }
    
    public func presentLoading(_ isLoading: Bool) {
        activityIndicator.startAnimating()
    }
    
    func presentError(_ message: String?) {
        errorLabel.text = "Invalid data"
    }
}
