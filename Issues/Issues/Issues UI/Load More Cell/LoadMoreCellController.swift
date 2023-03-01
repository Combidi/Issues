//
//  Created by Peter Combee on 10/02/2023.
//

import UIKit

public final class LoadMoreCellController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private let cell = LoadMoreCell()
    private let loadMore: () -> Void
    
    public init(loadMore: @escaping () -> Void) {
        self.loadMore = loadMore
        super.init()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        loadMore()
    }
}

import Core

extension LoadMoreCellController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell.isLoading = viewModel.isLoading
    }
}

extension LoadMoreCellController: ResourceErrorView {
    public func display(_ viewModel: ResourceLoadingErrorViewModel) {
        cell.message = viewModel.message
    }
}
