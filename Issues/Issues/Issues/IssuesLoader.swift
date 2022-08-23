//
//  Created by Peter Combee on 23/08/2022.
//

import Foundation

public protocol IssuesLoader {
    typealias Result = Swift.Result<[Issue], Error>
    typealias Completion = (Result) -> Void
    
    func loadIssues(completion: @escaping Completion)
}
