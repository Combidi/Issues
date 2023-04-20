//
//  Created by Peter Combee on 22/02/2023.
//

import Foundation

public class IssueViewModelMapper {
    private let dateFormatter: DateFormatter

    public init(locale: Locale = .current) {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = locale
    }
    
    public static var title: String {
        NSLocalizedString("ISSUES_VIEW_TITLE",
            tableName: "Issues",
            bundle: Bundle(for: Self.self),
            comment: "Title for the issues view"
        )
    }

    public func map(issues: [Issue]) -> [IssueViewModel] {
        issues.map { issue in
            IssueViewModel(
                name: issue.firstName + " " + issue.surname,
                submissionDate: dateFormatter.string(from: issue.submissionDate),
                subject: issue.subject
            )
        }
    }
}
