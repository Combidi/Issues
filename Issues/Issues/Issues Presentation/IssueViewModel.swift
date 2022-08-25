//
//  Created by Peter Combee on 23/08/2022.
//

public struct IssueViewModel {    
    let name: String
    let amountOfIssues: String
    let birthDate: String

    public init(name: String, amountOfIssues: String, birthDate: String) {
        self.name = name
        self.amountOfIssues = amountOfIssues
        self.birthDate = birthDate
    }
}
