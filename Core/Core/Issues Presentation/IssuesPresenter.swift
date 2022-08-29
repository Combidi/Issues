//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public protocol IssuesView {
    func present(issues: [IssueViewModel])
    func present(_ message: String)
    func presentLoading(_ flag: Bool)
}

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
                let viewModels = issues.map { issue -> IssueViewModel in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    
                    return IssueViewModel(
                        name: issue.firstName + " " + issue.surname,
                        amountOfIssues: String(issue.amountOfIssues),
                        birthDate: dateFormatter.string(from: issue.birthDate))
                }
                self?.view.present(issues: viewModels)

            case .failure:
                self?.view.present("Invalid data")

            }
        }
    }
}
