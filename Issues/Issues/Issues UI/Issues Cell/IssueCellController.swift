//
//  Created by Peter Combee on 10/02/2023.
//

import Core
import UIKit

public final class IssueCellController: NSObject, UITableViewDataSource {
    private let issue: IssueViewModel
    
    public init(issue: IssueViewModel) {
        self.issue = issue
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: IssueCell = tableView.dequeueReusableCell()
        cell.nameLabel.text = issue.name
        cell.subjectLabel.text = issue.subject
        cell.submissionDateLabel.text = issue.submissionDate
        return cell
    }
}
