//
//  Created by Peter Combee on 29/08/2022.
//

public protocol IssuesView: AnyObject {
    func present(issues: [IssueViewModel])
    func presentMessage(_ message: String?)
    func presentLoading(_ flag: Bool)
}
