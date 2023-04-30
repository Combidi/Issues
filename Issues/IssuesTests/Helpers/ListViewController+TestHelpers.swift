//
//  Created by Peter Combee on 30/04/2023.
//

import UIKit
import Issues

extension ListViewController {
    
    private var issuesSection: Int { 0 }
    private var loadMoreSection: Int { 1 }

    func numberOfRenderedIssueViews() -> Int {
        numberOfRows(in: issuesSection)
    }
    
    private func numberOfRows(in section: Int) -> Int {
        tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
    }

    func renderedName(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.nameLabel.text
    }
    
    func renderedSubject(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.subjectLabel.text
    }

    func renderedSubmissionDate(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.submissionDateLabel.text
    }
    
    private func issueView(atIndex index: Int = 0) -> IssueCell? {
        cell(at: IndexPath(row: index, section: issuesSection)) as? IssueCell
    }
    
    private func cell(at indexPath: IndexPath) -> UITableViewCell? {
        guard numberOfRows(in: indexPath.section) > indexPath.row else {
            return nil
        }
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    var isShowingLoadingIndicator: Bool {
        activityIndicator.isAnimating
    }
    
    func renderedErrorMessage() -> String? {
        errorLabel.text
    }
    
    func renderedLoadMoreErrorMessage() -> String? {
        renderedLoadMoreView()?.message
    }
    
    func simulateLoadMoreIssuesAction() {
        let index = IndexPath(row: 0, section: loadMoreSection)
        guard let cell = cell(at: index) else { return }
        tableView.delegate?.tableView?(tableView, willDisplay: cell, forRowAt: index)
    }
    
    var isShowingLoadMoreIndicator: Bool {
        renderedLoadMoreView()?.isLoading ?? false
    }
    
    private func renderedLoadMoreView() -> LoadMoreCell? {
        cell(at: IndexPath(row: 0, section: loadMoreSection)) as? LoadMoreCell
    }
}
