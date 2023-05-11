//
//  Created by Peter Combee on 10/05/2023.
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
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter(
            view: IssuesViewAdapter(viewController),
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: mapper.map
        )
        
        let presentationAdapter = LoadResourcePresentationAdapter<[Issue], IssuesViewAdapter>(
            load: loader.loadIssues
        )
               
        presentationAdapter.presenter = presenter
        
        viewController.load = presentationAdapter.loadResource
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private final class IssuesViewAdapter: ResourceView {
    private weak var viewController: ListViewController?
    
    init(_ viewController: ListViewController) {
        self.viewController = viewController
    }

    func display(_ viewModel: [IssueViewModel]) {
        let issueControllers = viewModel.map(IssueCellController.init(issue:))
        viewController?.display(sections: [issueControllers])
    }
}
