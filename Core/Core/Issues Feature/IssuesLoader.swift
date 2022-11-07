//
//  Created by Peter Combee on 29/08/2022.
//

import Foundation

public protocol IssuesLoader {
    typealias LoadIssuesResult = Swift.Result<[Issue], Error>
    typealias Completion = (LoadIssuesResult) -> Void
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func loadIssues(completion: @escaping Completion)
}
