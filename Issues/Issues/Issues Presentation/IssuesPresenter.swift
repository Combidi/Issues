//
//  Created by Peter Combee on 23/08/2022.
//

import Foundation

final class IssuesPresenter {
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
    }
    
    var view: IssuesView?
    
    let issuesTitle: String = "Issues"
    
    func load() {
        view?.presentLoading(true)
        loader.loadIssues(completion: { [weak view] result in
            switch result {
            case let .success(issues):
                view?.presentLoading(false)
                view?.present(issues: Self.map(issues: issues))
            case .failure:
                view?.presentError("Invalid data")
                view?.presentLoading(false)
            }
        })
    }
    
    static private func map(issues: [Issue]) -> [IssueViewModel] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        return issues.map {
            IssueViewModel(
                name: $0.firstName + " " + $0.surname,
                amountOfIssues: String($0.amountOfIssues),
                birthDate: dateFormatter.string(from: $0.birthDate)
            )
        }
    }
}