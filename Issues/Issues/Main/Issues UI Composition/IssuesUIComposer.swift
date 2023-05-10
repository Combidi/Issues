//
//  Created by Peter Combee on 10/05/2023.
//

import UIKit
import Core

public struct IssuesUIComposer {
    
    private init() {}
    
    public static func compose(
        withLoader loader: IssuesLoader,
        locale: Locale = .current
    ) -> UIViewController {
        let viewController = ListViewController()
        viewController.tableView.registerNibBasedCell(IssueCell.self)
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter<[Issue], IssuesViewAdapter>(
            view: IssuesViewAdapter(viewController),
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: mapper.map
        )
        
        let presentationAdapter = LoadResourcePresentationAdapter(
            loader: loader
        )
               
        presentationAdapter.presenter = presenter
        
        viewController.load = presentationAdapter.load
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<[Issue], IssuesViewAdapter>> {
    private let loader: IssuesLoader
    var presenter: Presenter!
    
    init(loader: IssuesLoader) {
        self.loader = loader
    }
        
    func load() {
        presenter.didStartLoading()
        loader.loadIssues { [weak self] result in
            guard let self else { return }
            self.dispatch { [weak self] in
                self?.present(result: result)
            }
        }
    }
    
    private func present(result: Result<[Issue], Error>) {
        switch result {
        case .success(let page):
            presenter.didFinishLoading(with: page)
            
        case .failure:
            presenter.didFinishLoadingWithError()
        }
    }
    
    private func dispatch(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
}

private final class IssuesViewAdapter: ResourceView {
    private weak var viewController: ListViewController?
    
    init(_ viewController: ListViewController) {
        self.viewController = viewController
    }

    func display(_ viewModel: [IssueViewModel]) {
        let issueControllers = viewModel.map(IssueCellController.init(issue:))
        viewController?.display(sections: [issueControllers])
    }
}
