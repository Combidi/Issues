//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public final class IssuesPresenter {
    
    private let loader: IssuesLoader
    private let loadingView: LoadingView
    private let errorView: ErrorView
    private let view: IssuesView
    private let mapper: ([Issue]) -> [IssueViewModel]
    
    public init(
        loader: IssuesLoader,
        loadingView: LoadingView,
        errorView: ErrorView,
        view: IssuesView,
        mapper: @escaping ([Issue]) -> [IssueViewModel]
    ) {
        self.loader = loader
        self.loadingView = loadingView
        self.errorView = errorView
        self.view = view
        self.mapper = mapper
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
                self.view.display(issues: self.mapper(issues))
                self.errorView.display(message: nil)
                
            case .failure:
                self.errorView.display(message: "Invalid data")
            }
        }
    }
}
