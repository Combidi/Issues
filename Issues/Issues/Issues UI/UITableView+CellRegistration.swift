//
//  Created by Peter Combee on 20/02/2023.
//

import UIKit

extension UITableView {
    func registerNibBasedCell<T: UITableViewCell>(_ T: T.Type) {
        let cellName = String(describing: T)
        register(UINib(nibName: cellName, bundle: .main), forCellReuseIdentifier: cellName)
    }
}
