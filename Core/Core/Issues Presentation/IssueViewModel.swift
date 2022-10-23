//
//  Created by Peter Combee on 29/08/2022.
//

public struct IssueViewModel: Equatable {
    public let name: String
    public let submissionDate: String
    public let subject: String

    public init(name: String, submissionDate: String, subject: String) {
        self.name = name
        self.submissionDate = submissionDate
        self.subject = subject
    }
}
