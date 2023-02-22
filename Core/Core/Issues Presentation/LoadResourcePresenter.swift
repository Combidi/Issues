//
//  Created by Peter Combee on 22/02/2023.
//

import Foundation

public final class LoadResourcePresenter {
    
    private let loader: IssuesLoader
    private let loadingView: LoadingView
    private let errorView: ErrorView
    private let view: IssuesView
    private let dateFormatter: DateFormatter
    
    public init(
        loader: IssuesLoader,
        loadingView: LoadingView,
        errorView: ErrorView,
        view: IssuesView,
        locale: Locale = .current
    ) {
        self.loader = loader
        self.loadingView = loadingView
        self.errorView = errorView
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
        loadingView.display(isLoading: true)
        loader.loadIssues { [weak self] result in
            guard let self = self else { return }
            self.loadingView.display(isLoading: false)
            switch result {
            case .success(let issues):
                self.view.display(issues: issues.map(self.map(issue:)))
                self.errorView.display(message: nil)
                
            case .failure:
                self.errorView.display(message: "Invalid data")
            }
        }
    }
    
    private func map(issue: Issue) -> IssueViewModel {
        IssueViewModel(
            name: issue.firstName + " " + issue.surname,
            submissionDate: dateFormatter.string(from: issue.submissionDate),
            subject: issue.subject
        )
    }
}
