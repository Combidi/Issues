//
//  Created by Peter Combee on 10/02/2023.
//

import UIKit

public final class LoadMoreCellController: NSObject, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: "LoadMoreCell")!
    }
}
