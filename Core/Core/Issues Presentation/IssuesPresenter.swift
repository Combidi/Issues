//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public final class IssuesPresenter {
    private let loader: IssuesLoader
    private let view: IssuesView
    
    public init(loader: IssuesLoader, view: IssuesView) {
        self.loader = loader
        self.view = view
    }
    
    public static let title: String = "Issues"

    public func loadIssues() {
        view.presentLoading(true)
        loader.loadIssues { [weak self] result in
            self?.view.presentLoading(false)
            switch result {
            case .success(let issues):
                self?.view.present(issues: issues.map(Self.map(issue:)))

            case .failure:
                self?.view.present("Invalid data")

            }
        }
    }
    
    static private func map(issue: Issue) -> IssueViewModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return IssueViewModel(
            name: issue.firstName + " " + issue.surname,
            amountOfIssues: String(issue.amountOfIssues),
            birthDate: dateFormatter.string(from: issue.birthDate))
    }
}
