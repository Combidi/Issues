//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public enum IssuesUIComposer {
    public static func compose(withLoader loader: IssuesLoader) -> UIViewController {
        let mainThreadDispatchingLoader = MainThreadDispatchingIssueLoaderDecorator(decoratee: loader)
        let presenter = IssuesPresenter(loader: mainThreadDispatchingLoader)
        let viewController = IssuesViewController(presenter: presenter)
        presenter.view = viewController
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
