//
//  Created by Peter Combee on 23/08/2022.
//

protocol IssuesView: AnyObject {
    func present(issues: [Issue])
    func presentLoading(_ isLoading: Bool)
    func presentError(_ message: String?)
}

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
                view?.present(issues: issues)
            case .failure:
                view?.presentError("Invalid data")
            }
        })
    }
}
