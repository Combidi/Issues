//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public final class IssuesViewController: UITableViewController {
    
    private let loader: IssuesLoader
    
    public init(loader: IssuesLoader) {
        self.loader = loader
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

    public override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        loader.loadIssues(completion: { [weak self] result in
            if Thread.isMainThread {
                switch result {
                case let .success(issues):
                    self?.issues = issues
                    self?.activityIndicator.stopAnimating()
                case .failure:
                    self?.errorLabel.text = "Invalid data"
                }
            } else {
                switch result {
                case let .success(issues):
                    DispatchQueue.main.async {
                        self?.issues = issues
                        self?.activityIndicator.stopAnimating()
                    }
                case .failure:
                    self?.errorLabel.text = "Invalid data"
                }
            }
        })
    }
    
    private var issues = [Issue]() {
        didSet { tableView.reloadData() }
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
}
