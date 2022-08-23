//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public enum IssuesUIComposer {
    public static func compose(withLoader loader: IssuesLoader) -> UIViewController {
        let mainThreadDispatchingLoader = MainThreadDispatchingIssueLoaderDecorator(decoratee: loader)
        let presenter = IssuesPresenter(loader: mainThreadDispatchingLoader)
        let viewController = IssuesViewController(presenter: presenter)
        presenter.view = WeakRefVirtualProxy(viewController)
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
    func present(issues: [Issue]) {
        object?.present(issues: issues)
    }
    
    func presentLoading(_ isLoading: Bool) {
        object?.presentLoading(isLoading)
    }
    
    func presentError(_ message: String?) {
        object?.presentError(message)
    }
}
