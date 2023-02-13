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
            view: MainThreadDispatchingIssueViewDecorator(decoratee: IssuesViewAdapter(viewController)),
            locale: locale
        )
        viewController.loadIssues = presenter.loadIssues
        viewController.title = IssuesPresenter.title
        return viewController
    }
}

private final class IssuesViewAdapter: IssuesView {
    private weak var viewController: IssuesViewController?
    
    init(_ viewController: IssuesViewController) {
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

extension MainThreadDispatchingIssueViewDecorator: IssuesLoadingView where Decoratee: IssuesLoadingView {
    func display(isLoading: Bool) {
        dispatch {
            self.decoratee.display(isLoading: isLoading)
        }
    }
}

extension MainThreadDispatchingIssueViewDecorator: IssuesErrorView where Decoratee: IssuesErrorView {
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

extension WeakRefVirtualProxy: IssuesLoadingView where T: IssuesLoadingView {
    func display(isLoading: Bool) {
        object?.display(isLoading: isLoading)
    }
}

extension WeakRefVirtualProxy: IssuesErrorView where T: IssuesErrorView {
    func display(message: String?) {
        object?.display(message: message)
    }
}
