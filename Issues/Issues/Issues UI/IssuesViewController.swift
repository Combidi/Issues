//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public final class IssuesViewController: UITableViewController, IssuesView {
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        loadIssues?()
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        issues.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func presentLoading(_ isLoading: Bool) {
        activityIndicator.startAnimating()
    }
    
    func presentError(_ message: String?) {
        errorLabel.text = "Invalid data"
    }
}
