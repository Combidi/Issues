//
//  Created by Peter Combee on 23/08/2022.
//

protocol IssuesView: AnyObject {
    func present(issues: [IssueViewModel])
    func presentLoading(_ isLoading: Bool)
    func presentError(_ message: String?)
}

struct IssueViewModel {
    let firstName: String
    let surname: String
    let amountOfIssues: String
    let birthDate: String
}

import Foundation

final class IssuesPresenter {
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
    }
    
    var view: IssuesView?
    
    func load() {
        loader.loadIssues(completion: { [weak view] result in
            switch result {
            case let .success(issues):
                view?.presentLoading(false)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
    
                let viewModels = issues.map {
                    IssueViewModel(
                        firstName: $0.firstName,
                        surname: $0.surname,
                        amountOfIssues: String($0.amountOfIssues),
                        birthDate: dateFormatter.string(from: $0.birthDate)
                    )
                }
                
                view?.present(issues: viewModels)
            case .failure:
                view?.presentError("Invalid data")
            }
        })
    }
}
