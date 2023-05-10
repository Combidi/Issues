//
//  Created by Peter Combee on 10/05/2023.
//

import UIKit
import Core

public struct IssuesUIComposer {
    
    private init() {}
    
    public static func compose(
        withLoader loader: @escaping (LoadIssuesCompletion) -> Void,
        locale: Locale = .current
    ) -> UIViewController {
        let viewController = ListViewController()
        viewController.tableView.registerNibBasedCell(IssueCell.self)
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter<Paginated<Issue>, IssuesViewAdapter>(
            view: IssuesViewAdapter(viewController, mapper: mapper),
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: { $0 }
        )
        
        let presentationAdapter = LoadResourcePresentationAdapter(
            loadIssues: loader
        )
               
        presentationAdapter.presenter = presenter
        
        viewController.load = presentationAdapter.load
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<Paginated<Issue>, IssuesViewAdapter>> {
    private let loadIssues: LoadIssues
    var presenter: Presenter!
    
    init(loadIssues: @escaping LoadIssues) {
        self.loadIssues = loadIssues
    }
    
    private var isLoading = false
    
    func load() {
        guard !isLoading else { return }
        presenter.didStartLoading()
        isLoading = true
        loadIssues { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            self.dispatch { [weak self] in
                self?.present(result: result)
            }
        }
    }
    
    private func present(result: Result<Paginated<Issue>, Error>) {
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
    private let mapper: IssueViewModelMapper
    
    init(_ viewController: ListViewController, mapper: IssueViewModelMapper) {
        self.viewController = viewController
        self.mapper = mapper
    }

    func display(_ viewModel: Paginated<Issue>) {
        guard let viewController else { return }
        
        let issueControllers: [ListViewController.CellController] = mapper
            .map(issues: viewModel.models)
            .map(IssueCellController.init(issue:))
        
        guard let loadMore = viewModel.loadMore else {
            viewController.display(sections: [issueControllers])
            return
        }
                
        let viewAdapter = IssuesViewAdapter(
            viewController,
            mapper: mapper
        )

        let adapter = LoadResourcePresentationAdapter(loadIssues: loadMore)
        
        let loadMoreController = LoadMoreCellController(loadMore: adapter.load)
        
        let presenter = LoadResourcePresenter(
            view: viewAdapter,
            loadingView: WeakRefVirtualProxy(loadMoreController),
            errorView: WeakRefVirtualProxy(loadMoreController),
            mapper: { $0 }
        )
        
        adapter.presenter = presenter
        
        viewController.display(sections: [issueControllers, [loadMoreController]])
    }
}
