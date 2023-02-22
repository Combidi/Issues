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
        let presenter = IssuesPresenter(
            loader: loader,
            loadingView: MainThreadDispatchingIssueViewDecorator(decoratee: WeakRefVirtualProxy(viewController)),
            errorView: MainThreadDispatchingIssueViewDecorator(decoratee: WeakRefVirtualProxy(viewController)),
            view: MainThreadDispatchingIssueViewDecorator(decoratee: IssuesViewAdapter(viewController)),
            mapper: mapper.map
        )
        viewController.load = presenter.loadIssues
        viewController.title = IssuesPresenter.title
        return viewController
    }
}

private final class IssuesViewAdapter: IssuesView {
    private weak var viewController: ListViewController?
    
    init(_ viewController: ListViewController) {
        self.viewController = viewController
    }
    
    func display(issues: [IssueViewModel]) {
        let cellControllers = issues.map(IssueCellController.init(issue:))
        viewController?.display(sections: [cellControllers])
    }
}

private final class MainThreadDispatchingIssueViewDecorator<Decoratee> {
    private let decoratee: Decoratee
    
    init(decoratee: Decoratee) {
        self.decoratee = decoratee
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

extension MainThreadDispatchingIssueViewDecorator: IssuesView where Decoratee: IssuesView {
    func display(issues: [IssueViewModel]) {
        dispatch {
            self.decoratee.display(issues: issues)
        }
    }
}

extension MainThreadDispatchingIssueViewDecorator: LoadingView where Decoratee: LoadingView {
    func display(isLoading: Bool) {
        dispatch {
            self.decoratee.display(isLoading: isLoading)
        }
    }
}

extension MainThreadDispatchingIssueViewDecorator: ErrorView where Decoratee: ErrorView {
    func display(message: String?) {
        dispatch {
            self.decoratee.display(message: message)
        }
    }
}

private final class WeakRefVirtualProxy<T: AnyObject> {
    private(set) weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: IssuesView where T: IssuesView {
    func display(issues: [IssueViewModel]) {
        object?.display(issues: issues)
    }
}

extension WeakRefVirtualProxy: LoadingView where T: LoadingView {
    func display(isLoading: Bool) {
        object?.display(isLoading: isLoading)
    }
}

extension WeakRefVirtualProxy: ErrorView where T: ErrorView {
    func display(message: String?) {
        object?.display(message: message)
    }
}
