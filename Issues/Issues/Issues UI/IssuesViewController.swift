//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

final class IssuesPresenter {
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
    }
    
    weak var view: IssuesViewController?
    
    func load() {
        loader.loadIssues(completion: { [weak view] result in
            switch result {
            case let .success(issues):
                view?.presentLoading(false)
                view?.present(issues: issues)
            case .failure:
                view?.presentError("Invalid data")
            }
        })
    }
}

public final class IssuesViewController: UITableViewController {
    
    private let presenter: IssuesPresenter
    
    init(presenter: IssuesPresenter) {
        self.presenter = presenter
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
        presenter.load()
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
