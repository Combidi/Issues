//
//  Created by Peter Combee on 23/08/2022.
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
        viewController.title = IssuesPresenter.title
        return viewController
    }
}

private class LoadResourcePresentationAdapter<Presenter: LoadResourcePresenter<[Issue], IssuesViewAdapter>> {
    private let loader: IssuesLoader
    private let presenter: Presenter
    
    init(loader: IssuesLoader, presenter: Presenter) {
        self.loader = loader
        self.presenter = presenter
    }
    
    func load() {
        presenter.didStartLoading()
        loader.loadIssues { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let issues):
                self.presenter.didFinishLoading(with: issues)
                
            case .failure:
                self.presenter.didFinishLoadingWithError()
            }
        }

    }
}

private final class IssuesViewAdapter: IssuesView, ResourceView {
    private weak var viewController: ListViewController?
    
    init(_ viewController: ListViewController) {
        self.viewController = viewController
    }
    
    func display(issues: [IssueViewModel]) {
        let cellControllers = issues.map(IssueCellController.init(issue:))
        viewController?.display(sections: [cellControllers])
    }
    
    func display(_ viewModel: [IssueViewModel]) {
        let cellControllers = viewModel.map(IssueCellController.init(issue:))
        viewController?.display(sections: [cellControllers])
    }
}

private final class MainThreadDispatchingDecorator: IssuesLoader {
    private let decoratee: IssuesLoader
    
    init(decoratee: IssuesLoader) {
        self.decoratee = decoratee
    }
    
    func loadIssues(completion: @escaping Completion) {
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

private final class WeakRefVirtualProxy<T: AnyObject> {
    private(set) weak var object: T?
    
    init(_ object: T) {
        self.object = object
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
