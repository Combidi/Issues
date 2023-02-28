//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public struct PaginatedIssues {
    let issues: [Issue]
    public let loadMore: (() -> PaginatedIssuesLoader)?

    public init(issues: [Issue], loadMore: (() -> PaginatedIssuesLoader)?) {
        self.issues = issues
        self.loadMore = loadMore
    }
}

public protocol PaginatedIssuesLoader {
    typealias LoadIssuesResult = Result<PaginatedIssues, Error>
    typealias Completion = (LoadIssuesResult) -> Void
    
    func loadIssues(completion: @escaping Completion)
}

public struct IssuesUIComposer {    
    private init() {}
    
    public static func compose(
        withLoader loader: PaginatedIssuesLoader,
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
            loader: MainThreadDispatchingDecorator(decoratee: loader)
        )
               
        presentationAdapter.presenter = presenter
        
        viewController.load = presentationAdapter.load
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<PaginatedIssues, IssuesViewAdapter>> {
    private let loader: PaginatedIssuesLoader
    var presenter: Presenter!
    
    init(loader: PaginatedIssuesLoader) {
        self.loader = loader
    }
    
    private var isLoading = false
    
    func load() {
        guard !isLoading else { return }
        presenter.didStartLoading()
        isLoading = true
        loader.loadIssues { [weak self] result in
            self?.isLoading = false
            guard let self else { return }
            switch result {
            case .success(let page):
                self.presenter.didFinishLoading(with: page)
                
            case .failure:
                self.presenter.didFinishLoadingWithError()
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
        
        guard let getLoadMoreLoader = viewModel.loadMore else {
            viewController.display(sections: [issueControllers])
            return
        }
                
        let viewAdapter = IssuesViewAdapter(
            viewController,
            mapper: mapper
        )
        
        let adapter = LoadResourcePresentationAdapter(loader: getLoadMoreLoader())
        
        let loadMoreController = LoadMoreCellController(loadMore: adapter.load)
        
        let presenter = LoadResourcePresenter(
            view: viewAdapter,
            loadingView: WeakRefVirtualProxy(loadMoreController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: { $0 }
        )
        
        adapter.presenter = presenter
        
        viewController.display(sections: [issueControllers, [loadMoreController]])
    }
}

private final class MainThreadDispatchingDecorator: PaginatedIssuesLoader {
    private let decoratee: PaginatedIssuesLoader
    
    init(decoratee: PaginatedIssuesLoader) {
        self.decoratee = decoratee
    }
    
    func loadIssues(completion: @escaping PaginatedIssuesLoader.Completion) {
        decoratee.loadIssues(completion: { result in
            if Thread.isMainThread {
                completion(result)
            } else {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        })
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
