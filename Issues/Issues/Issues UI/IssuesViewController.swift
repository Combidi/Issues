//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public final class IssuesViewController: UITableViewController, IssuesView {
    
    private let loadIssues: () -> Void
    
    init(loadIssues: @escaping () -> Void) {
        self.loadIssues = loadIssues
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { return nil }
    
    public private(set) var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    public private(set) var errorLabel = UILabel()
        
    private var issues = [Issue]() {
        didSet { tableView.reloadData() }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        loadIssues()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        issues.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = IssueCell()
        cell.firstNameLabel.text = issues[indexPath.row].firstName
        cell.surNameLabel.text = issues[indexPath.row].surname
        cell.issueCountLabel.text = String(issues[indexPath.row].amountOfIssues)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        cell.birthDateLabel.text = dateFormatter.string(for: issues[indexPath.row].birthDate)
        return cell
    }
    
    func present(issues: [Issue]) {
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
