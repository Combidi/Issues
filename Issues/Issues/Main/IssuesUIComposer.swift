//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public struct PaginatedIssues {
    public typealias Result = Swift.Result<PaginatedIssues, Error>
    public typealias LoadMore = () -> (Result) -> Void
    
    let issues: [Issue]
    let loadMore: LoadMore?

    public init(issues: [Issue], loadMore: LoadMore?) {
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
        viewController.tableView.registerNibBasedCell(LoadMoreCell.self)
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter<[Issue], IssuesViewAdapter>(
            view: IssuesViewAdapter(viewController),
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: mapper.map
        )
        let presentationAdapter = LoadResourcePresentationAdapter(
            loader: MainThreadDispatchingDecorator(decoratee: loader),
            presenter: presenter
        )
                
        viewController.load = presentationAdapter.load
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<[Issue], IssuesViewAdapter>> {
    private let loader: PaginatedIssuesLoader
    private let presenter: Presenter
    
    init(loader: PaginatedIssuesLoader, presenter: Presenter) {
        self.loader = loader
        self.presenter = presenter
    }
    
    func load() {
        presenter.didStartLoading()
        loader.loadIssues { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let page):
                self.presenter.didFinishLoading(with: page.issues)
                
            case .failure:
                self.presenter.didFinishLoadingWithError()
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
        let cellControllers = viewModel.map(IssueCellController.init(issue:))
        viewController?.display(sections: [cellControllers])
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
