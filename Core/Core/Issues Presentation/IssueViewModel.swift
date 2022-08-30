//
//  Created by Peter Combee on 29/08/2022.
//

public struct IssueViewModel: Equatable {
    public let name: String
    public let amountOfIssues: String
    public let birthDate: String

    public init(name: String, amountOfIssues: String, birthDate: String) {
        self.name = name
        self.amountOfIssues = amountOfIssues
        self.birthDate = birthDate
    }
}
