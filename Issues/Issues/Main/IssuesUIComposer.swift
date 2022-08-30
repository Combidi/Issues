//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public enum IssuesUIComposer {
    public static func compose(
        withLoader loader: IssuesLoader,
        locale: Locale = .current
    ) -> UIViewController {
        let mainThreadDispatchingLoader = MainThreadDispatchingIssueLoaderDecorator(decoratee: loader)
        let viewController = IssuesViewController()
        let presenter = IssuesPresenter(
            loader: mainThreadDispatchingLoader,
            view: WeakRefVirtualProxy(viewController),
            locale: locale
        )
        viewController.loadIssues = presenter.loadIssues
        viewController.title = IssuesPresenter.title
        return viewController
    }
}

private final class MainThreadDispatchingIssueLoaderDecorator: IssuesLoader {
    private let decoratee: IssuesLoader
    
    init(decoratee: IssuesLoader) {
        self.decoratee = decoratee
    }
    
    func loadIssues(completion: @escaping IssuesLoader.Completion) {
        decoratee.loadIssues { result in
            if Thread.isMainThread {
                completion(result)
            } else {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
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
    
    func presentLoading(_ isLoading: Bool) {
        object?.presentLoading(isLoading)
    }
    
    func presentMessage(_ message: String?) {
        object?.presentMessage(message)
    }
}
