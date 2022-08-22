//
//  Created by Peter Combee on 22/08/2022.
//

import Foundation

public struct Issue {
    public let firstName: String
    public let surname: String
    public let amountOfIssues: Int
    let birthDate: Date
    
    public init(firstName: String, surname: String, amountOfIssues: Int, birthDate: Date) {
        self.firstName = firstName
        self.surname = surname
        self.amountOfIssues = amountOfIssues
        self.birthDate = birthDate
    }
}

protocol IssueLoader {
    func load(completion: (Result<[Issue], Error>) -> Void)
}
