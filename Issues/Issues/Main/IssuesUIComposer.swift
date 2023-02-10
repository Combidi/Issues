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
        let viewController = IssuesViewController()
        let presenter = IssuesPresenter(
            loader: loader,
            loadingView: MainThreadDispatchingIssueViewDecorator(decoratee: WeakRefVirtualProxy(viewController)),
            errorView: MainThreadDispatchingIssueViewDecorator(decoratee: WeakRefVirtualProxy(viewController)),
            view: MainThreadDispatchingIssueViewDecorator(decoratee: IssuesViewControllerAdapter(viewController)),
            locale: locale
        )
        viewController.loadIssues = presenter.loadIssues
        viewController.title = IssuesPresenter.title
        return viewController
    }
}

private final class IssuesViewControllerAdapter: IssuesView {
    private weak var viewController: IssuesViewController?
    
    init(_ viewController: IssuesViewController) {
        self.viewController = viewController
    }
    
    func present(issues: [IssueViewModel]) {
        let cellControllers = issues.map(IssueCellController.init(issue:))
        viewController?.present(cellControllers)
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
    func present(issues: [IssueViewModel]) {
        dispatch {
            self.decoratee.present(issues: issues)
        }
    }
}

extension MainThreadDispatchingIssueViewDecorator: IssuesLoadingView where Decoratee: IssuesLoadingView {
    func presentLoading(_ flag: Bool) {
        dispatch {
            self.decoratee.presentLoading(flag)
        }
    }
}

extension MainThreadDispatchingIssueViewDecorator: IssuesErrorView where Decoratee: IssuesErrorView {
    func presentMessage(_ message: String?) {
        dispatch {
            self.decoratee.presentMessage(message)
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
    func present(issues: [IssueViewModel]) {
        object?.present(issues: issues)
    }
}

extension WeakRefVirtualProxy: IssuesLoadingView where T: IssuesLoadingView {
    func presentLoading(_ isLoading: Bool) {
        object?.presentLoading(isLoading)
    }
}

extension WeakRefVirtualProxy: IssuesErrorView where T: IssuesErrorView {
    func presentMessage(_ message: String?) {
        object?.presentMessage(message)
    }
}
