//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public struct PaginatedIssues {
    public typealias LoadMoreResult = Result<PaginatedIssues, Error>
    public typealias LoadMoreCompletion = (LoadMoreResult) -> Void
    public typealias LoadMore = (@escaping LoadMoreCompletion) -> Void
    
    let issues: [Issue]
    public let loadMore: LoadMore?

    public init(issues: [Issue], loadMore: LoadMore?) {
        self.issues = issues
        self.loadMore = loadMore
    }
}

public typealias LoadResult = Result<PaginatedIssues, Error>
public typealias LoadCompletion = (LoadResult) -> Void
public typealias Loader = (@escaping LoadCompletion) -> Void

public struct IssuesUIComposer {
    
    private init() {}
    
    public static func compose(
        withLoader loader: @escaping Loader,
        locale: Locale = .current
    ) -> UIViewController {
        let viewController = ListViewController()
        viewController.tableView.registerNibBasedCell(IssueCell.self)
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter<PaginatedIssues, IssuesViewAdapter>(
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

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<PaginatedIssues, IssuesViewAdapter>> {
    private let loadIssues: Loader
    var presenter: Presenter!
    
    init(loadIssues: @escaping Loader) {
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
    
    private func present(result: LoadResult) {
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

    func display(_ viewModel: PaginatedIssues) {
        guard let viewController else { return }
        
        let issueControllers: [ListViewController.CellController] = mapper
            .map(issues: viewModel.issues)
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

extension WeakRefVirtualProxy: ResourceLoadingView where T: ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: ResourceErrorView where T: ResourceErrorView {
    func display(_ viewModel: ResourceLoadingErrorViewModel) {
        object?.display(viewModel)
    }
}

extension ListViewController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        display(isLoading: viewModel.isLoading)
    }
}

extension ListViewController: ResourceErrorView {
    public func display(_ viewModel: ResourceLoadingErrorViewModel) {
        display(message: viewModel.message)
    }
}
