//
//  Created by Peter Combee on 10/02/2023.
//

import UIKit

public final class LoadMoreCellController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private let loadMore: () -> Void
    
    public init(loadMore: @escaping () -> Void) {
        self.loadMore = loadMore
        super.init()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell() as LoadMoreCell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        loadMore()
    }
}
