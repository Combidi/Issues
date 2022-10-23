//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public struct Issue: Equatable {
    public let firstName: String
    public let surname: String
    public let submissionDate: Date
    public let subject: String
    
    public init(firstName: String, surname: String, submissionDate: Date, subject: String) {
        self.firstName = firstName
        self.surname = surname
        self.submissionDate = submissionDate
        self.subject = subject
    }
}
