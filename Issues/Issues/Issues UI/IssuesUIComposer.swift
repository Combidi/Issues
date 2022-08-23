//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit

public enum IssuesUIComposer {
    public static func compose(withLoader loader: IssuesLoader) -> UIViewController {
        let presenter = IssuesPresenter(loader: loader)
        let viewController = IssuesViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }
}
