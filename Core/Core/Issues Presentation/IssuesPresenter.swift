//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public final class IssuesPresenter {
    private let loader: IssuesLoader
    private let view: IssuesView
    private let dateFormatter: DateFormatter
    
    public init(loader: IssuesLoader, view: IssuesView, locale: Locale = .current) {
        self.loader = loader
        self.view = view
        self.dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = locale
    }
    
    public static var title: String {
        NSLocalizedString("ISSUES_VIEW_TITLE",
            tableName: "Issues",
            bundle: Bundle(for: Self.self),
            comment: "Title for the issues view")
    }

    public func loadIssues() {
        view.presentLoading(true)
        loader.loadIssues { [weak self] result in
            guard let self = self else { return }
            self.view.presentLoading(false)
            switch result {
            case .success(let issues):
                self.view.present(issues: issues.map(self.map(issue:)))
                self.view.presentMessage(nil)
                
            case .failure:
                self.view.presentMessage("Invalid data")
            }
        }
    }
    
    private func map(issue: Issue) -> IssueViewModel {
        IssueViewModel(
            name: issue.firstName + " " + issue.surname,
            amountOfIssues: String(issue.amountOfIssues),
            birthDate: dateFormatter.string(from: issue.birthDate))
    }
}
