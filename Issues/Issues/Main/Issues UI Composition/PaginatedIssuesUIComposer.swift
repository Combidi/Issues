//
//  Created by Peter Combee on 23/08/2022.
//

import UIKit
import Core

public typealias LoadIssuesCompletion = (Result<Paginated<Issue>, Error>) -> Void
public typealias LoadIssues = (@escaping LoadIssuesCompletion) -> Void

private typealias PresentationAdapter = LoadResourcePresentationAdapter<Paginated<Issue>, IssuesViewAdapter>

public struct PaginatedIssuesUIComposer {
    
    private init() {}
    
    public static func compose(
        withLoader loader: @escaping LoadIssues,
        locale: Locale = .current
    ) -> UIViewController {
        let viewController = ListViewController()
        viewController.tableView.registerNibBasedCell(IssueCell.self)
        
        let mapper = IssueViewModelMapper(locale: locale)
        let presenter = LoadResourcePresenter(
            view: IssuesViewAdapter(viewController, mapper: mapper),
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            mapper: { $0 }
        )
        
        let presentationAdapter = PresentationAdapter(
            load: loader
        )
               
        presentationAdapter.presenter = presenter
        
        viewController.load = presentationAdapter.loadResource
        viewController.title = IssueViewModelMapper.title
        return viewController
    }
}

private final class IssuesViewAdapter: ResourceView {
    private weak var viewController: ListViewController?
    private let mapper: IssueViewModelMapper
    
    init(_ viewController: ListViewController, mapper: IssueViewModelMapper) {
        self.viewController = viewController
        self.mapper = mapper
    }

    func display(_ viewModel: Paginated<Issue>) {
        guard let viewController else { return }
        
        let issueControllers: [ListViewController.CellController] = mapper
            .map(issues: viewModel.models)
            .map(IssueCellController.init(issue:))
        
        guard let loadMore = viewModel.loadMore else {
            viewController.display(sections: [issueControllers])
            return
        }
                
        let viewAdapter = IssuesViewAdapter(
            viewController,
            mapper: mapper
        )

        let adapter = PresentationAdapter(load: loadMore)
        
        let loadMoreController = LoadMoreCellController(loadMore: adapter.loadResource)
        
        let presenter = LoadResourcePresenter(
            view: viewAdapter,
            loadingView: WeakRefVirtualProxy(loadMoreController),
            errorView: WeakRefVirtualProxy(loadMoreController),
            mapper: { $0 }
        )
        
        adapter.presenter = presenter
        
        viewController.display(sections: [issueControllers, [loadMoreController]])
    }
}
